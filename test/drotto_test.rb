require 'test_helper'

module BakerBob
  class BakerBobTest < DrOtto::Test
    include Config
    
    def setup
      override_config(
        bakerbob: {
          block_mode: 'irreversible',
          account_name: 'bittrex',
          posting_wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC',
          active_wif: '5JrvPrQeBBvCRdjv29iDvkwn3EQYZ9jqfAHzrCyUvfbEbRkrYFC',
          batch_vote_weight: '3.13 %',
          reserve_vote_weight: '0.00 %',
          minimum_bid: '0.100 SBD'
          maximum_bid: '0.500 SBD'
        }, chain_options: {
          chain: 'steem',
          url: 'https://steemd.steemit.com'
        }
      )
    end
    
    def test_block_span
      assert BakerBob.block_span
    end
    
    def test_backoff
      assert BakerBob.backoff
    end
    
    def test_backoff
      assert BakerBob.find_bids(0)
    end
  end
end
