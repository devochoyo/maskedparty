// FILE LOCATION: services/countries.js
// Mirrors lib/services/countries.dart.
(function (global) {
  "use strict";

  const CountryService = {
    async detectCountry() {
      try {
        const result = await ApiConfig.get(ApiEndpoints.detectCountry, null);
        if (result && result.success === true && result.data && typeof result.data.country_name === "string" && result.data.country_name) {
          return result.data.country_name;
        }
        return null;
      } catch (e) {
        return null;
      }
    },
  };

  global.CountryService = CountryService;
})(window);
