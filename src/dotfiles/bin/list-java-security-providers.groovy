#!/usr/bin/env groovy

import java.security.Security

for (provider : Security.getProviders()) {
  for (service : provider.getServices()) {
    print(service)
  }
}
