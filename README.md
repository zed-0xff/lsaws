# Lsaws

User-friendly AWS resources listing tool

## Usage

    # lsaws

    Usage: lsaws [options] <sdk> [entity_type]
        -o, --output FMT                 Format: js/json/json-stream/table/text/yaml
            --no-header                  Suppress header
        -x                               Shortcut for "-o text --no-header"
            --tags                       Show tags
        -f, --filter K=V                 Add filter
        -C, --columns C                  Show only specified column(s)
            --max-results N              Fetch only specified number of results
            --max-width X                max text width for table/text mode, default: auto
    
        -v, --verbose                    Verbose output
            --debug
    
        -L, --list                       List SDKs or entity types
        -A, --all                        List all entity types within SDK


### Listing installed SDKs

    # lsaws -L

    accessanalyzer
    account
    acm
    acmpca
    alexaforbusiness
    amplify
    amplifybackend
    amplifyuibuilder
    apigateway
    apigatewaymanagementapi
    apigatewayv2
    appconfig
    appconfigdata
    appflow
    appintegrationsservice
    applicationautoscaling
    applicationcostprofiler
    applicationdiscoveryservice
    applicationinsights
    appmesh
    appregistry
    apprunner
    appstream
    appsync
    arczonalshift
    ...


### Listing listable entities from EC2 sdk

    # lsaws ec2 -L

    account_attributes
    address_transfers
    addresses
    availability_zones
    aws_network_performance_metric_subscriptions
    bundle_tasks
    capacity_reservation_fleets
    capacity_reservations
    carrier_gateways
    classic_link_instances
    client_vpn_endpoints
    coip_pools
    conversion_tasks
    customer_gateways
    dhcp_options
    egress_only_internet_gateways
    elastic_gpus
    export_image_tasks
    export_tasks
    fast_launch_images
    fast_snapshot_restores
    fleets
    flow_logs
    fpga_images
    host_reservation_offerings
    ...


### Listing EC2 instances

    # lsaws ec2

    ┌─────────────────────┬─────────────┬───────────────────────┬────────────────────┬─────────────────────────┐
    │ instance_id         │ name        │ vpc_id                │ private_ip_address │ launch_time             │
    ├─────────────────────┼─────────────┼───────────────────────┼────────────────────┼─────────────────────────┤
    │ i-1234567890abcdef0 │ my-instance │ vpc-1234567890abcdef0 │ 10-0-0-157         │ 2022-11-15 10:48:59 UTC │
    └─────────────────────┴─────────────┴───────────────────────┴────────────────────┴─────────────────────────┘

### Listing specific columns of EC2 images as json-stream

    # lsaws ec2 images -c image_id,creation_date -o js

    {"image_id":"ami-1234e6197567838b4","creation_date":"2023-01-11T13:02:00.000Z"}
    {"image_id":"ami-1234f58a167898416","creation_date":"2023-01-11T02:02:00.000Z"}
    {"image_id":"ami-12341a1fd567897a8","creation_date":"2023-01-01T01:02:00.000Z"}

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lsaws project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zed-0xff/lsaws/blob/master/CODE_OF_CONDUCT.md).
