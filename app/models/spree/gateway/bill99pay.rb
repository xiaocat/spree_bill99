module Spree
  class Gateway::Bill99pay < Gateway
    preference :merchantAcctId, :string   #账户
    preference :payKey, :string  #人名币网关密钥
    preference :queryKey, :string  #查询密钥
    preference :server_public_key, :string #快钱公钥
    preference :client_private_key, :string #商户私钥
    preference :iconUrl, :string

    def supports?(source)
      true
    end

    def provider
    end

    def purchase(amount, express_checkout, gateway_options={})
      Class.new do
        def success?; true; end
        def authorization; nil; end
      end.new
    end

    def auto_capture?
      true
    end

    def method_type
      'bill99pay'
    end

  end
end
