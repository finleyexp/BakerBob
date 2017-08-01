require 'test_helper'

module BakerBob
  class UtilsTest < BakerBob::Test
    include Utils
    
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
    
    def test_name_error
      assert_raises NameError do
        assert reset_api
      end
    end
    
    def test_trace
      assert_nil trace "trace"
    end
    
    def test_debug
      assert_nil debug "debug"
    end
    
    def test_info
      assert_nil info "info"
    end
    
    def test_info_detail
      assert_nil info("info", Exception.new)
    end
    
    def test_warning
      assert_nil warning "warning"
    end
    
    def test_error
      assert_nil error "error"
    end
    
    def test_unknown_type
      assert_nil console(:BOGUS, "unknown_type")
    end
    
    def test_parse_slug
      author, permlink = parse_slug '@author/permlink'
      
      assert_equal 'author', author
      assert_equal 'permlink', permlink
    end
    
    def test_parse_slug_to_comment
      url = 'https://steemit.com/chainbb-general/@howtostartablog/the-joke-is-always-in-the-comments-8-sbd-contest#@btcvenom/re-howtostartablog-the-joke-is-always-in-the-comments-8-sbd-contest-20170624t115213474z'
      author, permlink = parse_slug url
      
      assert_equal 'btcvenom', author
      assert_equal 're-howtostartablog-the-joke-is-always-in-the-comments-8-sbd-contest-20170624t115213474z', permlink
    end
    
    def test_merge
      merge_options = {
        markup: :html,
        content_type: 'content_type',
        vote_weight_percent: 'vote_weight_percent',
        vote_type: 'vote_type',
        account_name: 'account_name',
        from: ['foo', 'bar']
      }
      
      expected_merge = "<p>This content_type has received a vote_weight_percent % vote_type from @account_name thanks to: @foo, @bar.</p>\n"
      assert_equal expected_merge, merge(merge_options)
    end
    
    def test_merge_markdown
      merge_options = {
        markup: :markdown,
        content_type: 'content_type',
        vote_weight_percent: 'vote_weight_percent',
        vote_type: 'vote_type',
        account_name: 'account_name',
        from: ['foo', 'bar']
      }
      
      expected_merge = "This content_type has received a vote_weight_percent % vote_type from @account_name thanks to: @foo, @bar.\n"
      assert_equal expected_merge, merge(merge_options)
    end
    
    def test_merge_nil
      refute merge
    end
  end
end
