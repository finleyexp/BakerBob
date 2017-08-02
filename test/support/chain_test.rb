require 'test_helper'

module BakerBob
  class ChainTest < BakerBob::Test
    include Chain
    
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
    end
    
    def test_reset_api
      assert_nil reset_api
    end
    
    def test_backoff
      assert backoff
    end
    
    def test_reset_properties
      assert_nil reset_properties
    end
    
    def test_properties
      assert properties
    end
    
    def test_properties_timeout
      assert properties
      
      Delorean.jump 31 do
        assert properties
      end
    end
    
    def test_comment
      refute_nil find_comment('inertia', 'macintosh-napintosh')
    end
    
    def test_comment_bogus
      assert_nil find_comment('bogus', 'bogus')
    end
    
    def test_vote
      bid1 = {
        from: 'from',
        author: 'author',
        permlink: 'permlink',
        parent_permlink: 'parent_permlink',
        parent_author: 'parent_author',
        amount: '0.200 SBD',
        timestamp: 'timestamp',
        trx_id: 'id'
      }
      
      bid2 = {
        from: 'from',
        author: 'author',
        permlink: 'permlink',
        parent_permlink: 'parent_permlink',
        parent_author: 'parent_author',
        amount: '0.020 SBD',
        timestamp: 'timestamp',
        trx_id: 'id'
      }
      
      bid3 = {
        from: 'from',
        author: 'author',
        permlink: 'permlink',
        parent_permlink: 'parent_permlink',
        parent_author: 'parent_author',
        amount: '0.002SBD',
        timestamp: 'timestamp',
        trx_id: 'id'
      }
      
      expected_stacked_bid = {
        from: ['from', 'from', 'from'],
        author: 'author',
        permlink: 'permlink',
        parent_permlink: 'parent_permlink',
        parent_author: 'parent_author',
        amount: ['0.200 SBD', '0.020 SBD', '0.002 SBD'],
        timestamp: 'timestamp',
        trx_id: 'id'
      }
      
      result = vote([bid1, bid2, bid3])
      bids = result.keys
      assert_equal 1, bids.size
      assert_equal expected_stacked_bid[:from], bids.first[:from]
      assert_equal expected_stacked_bid[:author], bids.first[:author]
      assert_equal expected_stacked_bid[:permlink], bids.first[:permlink]
      assert_equal expected_stacked_bid[:parent_permlink], bids.first[:parent_permlink]
      assert_equal expected_stacked_bid[:amount], bids.first[:amount]
      assert_equal expected_stacked_bid[:timestamp], bids.first[:timestamp]
      assert_equal expected_stacked_bid[:trx_id], bids.first[:trx_id]
    end
    
    def test_vote_invalid
      bid = {
        from: '',
        author: '',
        permlink: '',
        parent_permlink: '',
        parent_author: '',
        amount: '',
        timestamp: '',
        trx_id: ''
      }
      
      assert_raises FloatDomainError do
        refute_nil vote([bid])
      end
    end
    
    def test_voted?
      comment = find_comment('inertia', 'macintosh-napintosh')
      refute voted?(comment)
    end
    
    def test_can_vote?
      comment = find_comment('inertia', 'macintosh-napintosh')
      refute can_vote?(comment)
    end
    
    def test_current_voting_power
      assert current_voting_power
    end
  end
end
