module Spree
  class Bill99payController < StoreController
    ssl_allowed
    skip_before_filter :verify_authenticity_token

    def bill99_url(action, options) # :nodoc: all
      options.reject!{|k,v| v.blank? }
      key = OpenSSL::PKey::RSA.new(payment_method.preferences[:client_private_key].gsub('\n', "\n"))
      options << ['signMsg', Base64.encode64(key.sign(OpenSSL::Digest::SHA1.new, options.map{|k,v| "#{k}=#{v}" }.join('&')))]
      cgi_escape_action_and_options(action, options)
    end

    def cgi_escape_action_and_options(action, options) # :nodoc: all
      "#{action}?#{options.sort.map{|k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" }.join('&')}"
    end

    def checkout
      order = current_order || raise(ActiveRecord::RecordNotFound)
      bankId = params[:bankId]

      url = bill99_url("https://www.99bill.com/gateway/recvMerchantInfoAction.htm", [
          ["inputCharset", 1],
          ["pageUrl", request.url.sub(request.fullpath, '')  + '/bill99pay/notify?id=' + order.id.to_s + '&payment_method_id=' + params[:payment_method_id].to_s],
          ["bgUrl", request.url.sub(request.fullpath,'') + '/bill99pay/notify?id=' + order.id.to_s + '&payment_method_id=' + params[:payment_method_id].to_s],
          ["version", "v2.0"],
          ["language", 1],
          ["signType", 4],
          ["merchantAcctId", payment_method.preferences[:merchantAcctId]],
          ["orderId", order.number],
          ["orderAmount", (order.total*100).to_i],
          ["orderTime", order.created_at && order.created_at.strftime("%Y%m%d%H%M%S")],
          ["productName", "#{order.line_items[0].product.name}等#{order.line_items.count}件"],
          ["productNum", order.line_items.count],
          ["productDesc", "#{order.number}"],
          ["payType", bankId ? "10" : "00"],
          ["bankId", bankId ? bankId.upcase : nil],
      ])

      render json:  { 'url' => url }
    end

    def notify
      order = Spree::Order.find(params[:id]) || raise(ActiveRecord::RecordNotFound)

      if order.complete?
        success_return order
        return
      end

      cert = OpenSSL::X509::Certificate.new(payment_method.preferences[:server_public_key].gsub('\n', "\n")) rescue nil
      is_valid = cert && cert.public_key.verify(OpenSSL::Digest::SHA1.new, Base64.decode64(params[:signMsg]), (%w[merchantAcctId version language signType payType bankId orderId orderTime orderAmount dealId bankDealId dealTime payAmount fee ext1 ext2 payResult errCode].map{|k| (v=params[k]) && !v.blank? ? [k,v] : nil}.compact).map{|k,v|"#{k}=#{v}"}.join('&'))

      unless params[:payResult] == "10" && params[:orderAmount] == (order.total * 100).to_i.to_s && is_valid
        failure_return order
        return
      end

      order.payments.create!({
        :source => Spree::Bill99PayNotify.create({
          :merchant_acct_id => params[:merchantAcctId],
          :bank_id => params[:bankId],
          :order_id => params[:orderId],
          :order_amount => params[:orderAmount],
          :deal_id => params[:dealId],
          :pay_amount => params[:payAmount],
          :fee => params[:fee],
          :source_data => params.to_json
        }),
        :amount => order.total,
        :payment_method => payment_method
      })

      order.next
      if order.complete?
        success_return order
      else
        failure_return order
      end
    end

    def success_return(order)
      respond_to do |format|
        format.html { redirect_to "/orders/#{order.number}" }
        format.xml { render :text => "<result>1</result><redirecturl>http://#{request.url.sub(request.fullpath, '')}/orders/#{order.number}</redirecturl>" }
      end
    end

    def failure_return(order)
      respond_to do |format|
        format.html { redirect_to "/orders/#{order.number}" }
        format.xml { render :text => "<result>0</result>" }
      end
    end

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end
  end
end