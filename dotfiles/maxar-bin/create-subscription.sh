#!/usr/bin/env bash
# create event subscriptions for a local AIT-b-v2 instance
# assumes port 80 and a particular IP

ESCP=$(eureka -e reg event-service-consumer-proxy)

mxcurl -v $ESCP/subscriptions -H "Content-Type: application/json" \
    -d '{
            "name": "MCS.AMS.newAncillaryMetadata_reg-tbozeman-k8s_AIT_BACKEND_SERVICE_V2_testing",
            "eventSubscription": "MCS.AMS.newAncillaryMetadata",
            "eventVersionSubscription": "*",
            "deliveryMethod": {
                "type": "http-push",
                "eventLimit": 3,
                "endpoint": "http://10.92.80.56/events"
            }
        }'

mxcurl -v $ESCP/subscriptions -H "Content-Type: application/json" \
    -d '{
            "name": "IMS.AcquisitionGroundStateChange_reg-tbozeman-k8s_AIT_BACKEND_SERVICE_V2_testing",
            "eventSubscription": "IMS.AcquisitionGroundStateChange",
            "eventVersionSubscription": "*",
            "deliveryMethod": {
                "type": "http-push",
                "eventLimit": 3,
                "endpoint": "http://10.92.80.56/events"
            }
        }'
