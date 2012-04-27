window.OAuthProxy = function(site, options) {
  var siteProxyUrl;
  if (typeof(options) === "undefined") {
    options = {};
  }
  if (!options.proxyUrl) {
    options.proxyUrl = $("script[src$='oauth_proxy.js']").attr("src").replace("oauth_proxy.js","");
  }
  siteProxyUrl = options.proxyUrl + site;
  if (options.loginSelector) {
    $(options.loginSelector).attr({href: siteProxyUrl + "/login", target: "_blank"});
  }
  return {
    siteProxyUrl: siteProxyUrl,
    get: function(url, callback) {
      $.ajax({
        url: this.siteProxyUrl + "/api",
        data: {url: url},
        dataType: "jsonp",
        success: function(data) {
          callback(data);
        }
      });
    }
  };
};
