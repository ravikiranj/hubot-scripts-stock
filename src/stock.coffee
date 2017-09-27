# Description:
#   Get a stock price
#   Heavily ripped from "stock.coffee" by eliperkins and "stock-short.cofee" by jamiew
#
# Dependencies:
#   request
#
# Configuration:
#   None
#
# Commands:
#   hubot stock <ticker> - Get a stock price
#
# Author:
#   eliperkins
#   maddox
#   johnwyles
#   jamiew
#   Jeremy Brown <jeremy@tenfourty.com>
#   ravikiranj

request = require "request"

module.exports = (robot) ->

    ## typeIsArray
    typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is '[object Array]'

    robot.respond /stock (\S+)$/i, (msg) ->
        ticker = escape(msg.match[1])
        # Sample URL: https://query2.finance.yahoo.com/v10/finance/quoteSummary/MSFT?modules=price
        url = "https://query2.finance.yahoo.com/v10/finance/quoteSummary/#{ticker}?modules=price"
        errorMsg = "Error fetching stock info for ticker = #{ticker}"
        request.get url, (error, response, data) ->
            if not response or response.statusCode != 200 or not data
                robot.logger.error "URL = #{url}, status code = #{response.statusCode}, data = #{data}"
                msg.send errorMsg
                return

            try
                resp = JSON.parse(data)
                if resp.quoteSummary? and resp.quoteSummary.result? and typeIsArray(resp.quoteSummary.result) and
                resp.quoteSummary.result.length > 0 and resp.quoteSummary.result[0].price?
                    stockInfo = resp.quoteSummary.result[0].price
                    if stockInfo.regularMarketChange? and stockInfo.regularMarketChangePercent? and stockInfo.regularMarketPrice?
                        arrow = if stockInfo.regularMarketChange.raw > 0.0 then "⬆" else "⬇"
                        msg.send "#{ticker.toUpperCase()}: $#{stockInfo.regularMarketPrice.fmt} #{arrow} " +
                        "#{stockInfo.regularMarketChange.fmt} (#{stockInfo.regularMarketChangePercent.fmt})"
                    else
                        robot.logger.error "Missing stock info for ticker = #{ticker}"
                        msg.send errorMsg
                else
                    msg.send errorMsg
                    robot.logger.error "Bad response format for ticker = #{ticker}"
            catch error
                robot.logger.error "Exception when fetching stock info for ticker = #{ticker}, error = #{error}"
                msg.send errorMsg
