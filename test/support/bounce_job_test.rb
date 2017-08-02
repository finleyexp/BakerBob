require 'test_helper'

module BakerBob
  class BakerBobTest < BakerBob::Test
    include Config
    
    def setup
      override_config(
        bakerbob: {
          block_mode: 'irreversible',
          account_name: 'social',
          posting_wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC',
          active_wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC',
          batch_vote_weight: '3.13 %',
          reserve_vote_weight: '0.00 %',
          minimum_bid: '0.100 SBD',
          maximum_bid: '0.500 SBD',
          blacklist: 'mikethemug'
        }, chain_options: {
          chain: 'steem',
          url: 'https://steemd.steemit.com'
        }
      )
      
      @job = BounceJob.new(200)
    end
    
    def test_report
      assert @job.perform(pretend: true)
    end
    
    def test_report_today
      job = BounceJob.new('today')
      
      assert job.perform(pretend: true)
    end
    
    def test_stream
      count = 10
      assert_equal count, @job.stream(count)
    end
    
    def test_bounce
      assert @job.bounce('from', 'amount', 'id')
    end
    
    def test_bounced?
      refute @job.bounced?('id')
    end
    
    def test_bid_stacking_no_bounce
      # Multiple bids for the same slug should stack into one bid.  There should
      # be no bounce for any of the bids that went into the stack.
    end
    
    # def test_shall_bounce?
    #   Struct.new("Transaction", :trx_id, :op)
    #   
    #   refute @job.shall_bounce?(tx)
    # end
  end
end
