module BakerBob
  class BounceJob
    include Chain
    
    def initialize(limit = nil)
      @limit = limit
      
      init_transactions unless @limit.nil?
    end
    
    def init_transactions
      return unless @transactions.nil?
      
      response = nil
      
      if @limit.to_i > 0
        with_api { |api| response = api.get_account_history(account_name, -@limit.to_i, @limit.to_i) }
      else
        with_api { |api| response = api.get_account_history(account_name, -10000, 10000) }
      end
      
      @memos = nil
      @transactions = response.result
    end
    
    def perform(pretend = false)
      
      if voting_in_progress?
        debug "Voting in progress, bounce suspended ..."
        sleep 60
        return
      end
      
      block_num = head_block
      end_block_num = head_block - (base_block_span * 1.25)
      totals = {}
      transaction = Radiator::Transaction.new(chain_options.merge(wif: active_wif))
      
      @transactions.each do |index, tx|
        case @limit
        when 'today'
          timestamp = Time.parse(tx.timestamp + 'Z')
          today = Time.now.utc - 86400
          next if timestamp < today
        end
      
        break if tx.block >= end_block_num
        type = tx['op'].first
        next unless type == 'transfer'
        
        id = tx.trx_id
        op = tx['op'].last
        from = op.from
        to = op.to
        amount = op.amount
        memo = op.memo
        timestamp = op.timestamp
          
        next unless to == account_name
        
        author, permlink = parse_slug(memo) rescue [nil, nil]
        next if author.nil? || permlink.nil?
        comment = find_comment(author, permlink)
        next if comment.nil?
        
        next unless can_vote?(comment)
        next unless comment.author == author
        next if voted?(comment)
        next unless shall_bounce?(tx)
        next if bounced?(id)
        
        totals[amount.split(' ').last] ||= 0
        totals[amount.split(' ').last] += amount.split(' ').first.to_f
        warning "Need to bounce #{amount} (original memo: #{memo})"
        
        transaction.operations << bounce(from, amount, id)
      end
      
      totals.each do |k, v|
        info "Need to bounce total: #{v} #{k}"
      end
      
      return true if transaction.operations.size == 0
        
      response = transaction.process(!pretend)
      
      return true if pretend
      
      if !!response && !!response.error
        message = response.error.message
        
        if message.to_s =~ /missing required active authority/
          error "Failed transfer: Check active key."
          
          return false
        end
      end
      
      response
    end
    
    # This method will look for transfers that must immediately bounce because
    # they've already been voted on, or various other criteria.  Basically, the
    # user sent a transfer that is invalid and can't possibly be processed in
    # a future timeframe.
    def stream(max_ops = -1)
      @limit ||= 200
      stream = Radiator::Stream.new(chain_options.dup)
      count = 0
      
      info "Streaming bids to #{account_name}; starting at block #{head_block}; current time: #{block_time} ..."
      
      loop do
        begin
          stream.transactions do |tx, id|
            if voting_in_progress?
              debug "Voting in progress, bounce stream suspended ..."
              sleep 60
              redo
            end
            
            tx.operations.each do |type, op|
              count = count + 1
              return count if max_ops > 0 && max_ops <= count
              next unless type == 'transfer'
              needs_bounce = false
              
              from = op.from
              to = op.to
              amount = op.amount
              memo = op.memo
              timestamp = op.timestamp
                
              next unless to == account_name
              
              author, permlink = parse_slug(memo) rescue [nil, nil]
              
              if author.nil? || permlink.nil?
                debug "Bad memo.  Original memo: #{memo}"
                needs_bounce = true
              end
              
              comment = find_comment(author, permlink)
              
              if comment.nil?
                debug "No such comment.  Original memo: #{memo}"
                needs_bounce = true
              end
              
              unless can_vote?(comment)
                debug "Cannot vote.  Original memo: #{memo}"
                needs_bounce = true
              end
              
              if !!comment && comment.author != author
                debug "Sanity check failed.  Comment author not the author parsed.  Original memo: #{memo}"
                needs_bounce = true
              end
              
              if voted?(comment)
                debug "Already voted.  Original memo: #{memo}"
                needs_bounce = true
              end
              
              # Final check.  Don't bounce if already bounced.  This should only
              # happen under a race condition (rarely).  So we hold off dumping
              # the transactions in memory until we actually need to know.
              if needs_bounce
                @transactions = nil # dump
                
                if bounced?(id)
                  debug "Already bounced transaction: #{id}"
                  needs_bounce = false
                end
              end
              
              if needs_bounce
                transaction = Radiator::Transaction.new(chain_options.merge(wif: active_wif))
                transaction.operations << bounce(from, amount, id)
                response = transaction.process(true)
                
                if !!response && !!response.error
                  message = response.error.message
                  
                  if message.to_s =~ /missing required active authority/
                    error "Failed transfer: Check active key."
                  end
                else
                  debug "Bounced", response
                end
                
                next
              end
                
              info "Allowing #{amount} (original memo: #{memo})"
            end
          end
        rescue => e
          warning e.inspect, e
          reset_api
          sleep backoff
        end
      end
    end
    
    def bounce(from, amount, id)
      {
        type: :transfer,
        from: account_name,
        to: from,
        amount: amount,
        memo: "Unable to accept bid.  (ID:#{id})"
      }
    end
    
    def bounced?(id_to_check)
      init_transactions
      
      @memos ||= @transactions.map do |index, tx|
        type = tx['op'].first
        next unless type == 'transfer'
        
        id = tx.trx_id
        op = tx['op'].last
        f = op['from']
        m = op['memo']
        
        next unless f == account_name
        next if m.empty?
          
        m
      end.compact
      
      @memos.each do |memo|
        if memo =~ /.*\(ID:#{id_to_check}\)$/
          debug "Already bounced: #{id_to_check}"
          return true
        end
      end
      
      false
    end
    
    # Bounce a transfer if it hasn't aready been bounced, unless it's too old
    # to process.
    def shall_bounce?(tx)
      id_to_bounce = tx.trx_id
      memo = tx['op'].last['memo']
      timestamp = Time.parse(tx.timestamp + 'Z')
      @newest_timestamp ||= @transactions.map do |tx|
        Time.parse(tx.last.timestamp + 'Z')
      end.max
      @oldest_timestamp ||= @transactions.map do |tx|
        Time.parse(tx.last.timestamp + 'Z')
      end.min
      
      if (timestamp - @oldest_timestamp) < 1000
        debug "Too old to bounce."
        return false
      end
      
      debug "Checking if #{id_to_bounce} is in memo history."
      
      !bounced?(id_to_bounce)
    end
    
    # This bypasses the usual validations and issues a bounce for a transaction.
    def manual_bounce!(trx_id)
      init_transactions
      
      totals = {}
      transaction = Radiator::Transaction.new(chain_options.merge(wif: active_wif))
      
      @transactions.each do |index, tx|
        type = tx['op'].first
        next unless type == 'transfer'
        
        id = tx.trx_id
        next unless id == trx_id
        
        op = tx['op'].last
        from = op.from
        to = op.to
        amount = op.amount
        memo = op.memo
        timestamp = op.timestamp
          
        next unless to == account_name
        
        author, permlink = parse_slug(memo) rescue [nil, nil]
        next if author.nil? || permlink.nil?
        comment = find_comment(author, permlink)
        next if comment.nil?
        
        next unless comment.author == author
        
        totals[amount.split(' ').last] ||= 0
        totals[amount.split(' ').last] += amount.split(' ').first.to_f
        warning "Need to bounce #{amount} (original memo: #{memo})"
        
        transaction.operations << bounce(from, amount, id)
      end
      
      totals.each do |k, v|
        info "Need to bounce total: #{v} #{k}"
      end
      
      return true if transaction.operations.size == 0
        
      response = transaction.process(true)
      
      if !!response && !!response.error
        message = response.error.message
        
        if message.to_s =~ /missing required active authority/
          error "Failed transfer: Check active key."
          
          return false
        end
      end
      
      response
    end
  end
end
