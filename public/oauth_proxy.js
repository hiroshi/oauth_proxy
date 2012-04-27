window.OAuthProxy = {
  init: function(url, site) {
    return {
      proxyUrl: url,
      site: site,
      get: function(url, callback) {
        $.ajax({
          url: this.proxyUrl + this.site + "/api",
          data: {url: url},
          dataType: "jsonp",
          success: function(data) {
            callback(data);
          }
        });
      }
    };
  }
}
