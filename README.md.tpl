# Lsaws

User-friendly AWS resources listing tool

## Usage

% lsaws

### Listing installed SDKs

% lsaws -L

### Listing listable entities from EC2 sdk

% lsaws ec2 -L

### Listing EC2 instances

    # lsaws ec2

    ┌─────────────────────┬─────────────┬───────────────────────┬────────────────────┬─────────────────────────┐
    │ instance_id         │ name        │ vpc_id                │ private_ip_address │ launch_time             │
    ├─────────────────────┼─────────────┼───────────────────────┼────────────────────┼─────────────────────────┤
    │ i-1234567890abcdef0 │ my-instance │ vpc-1234567890abcdef0 │ 10-0-0-157         │ 2022-11-15 10:48:59 UTC │
    └─────────────────────┴─────────────┴───────────────────────┴────────────────────┴─────────────────────────┘

### Listing specific columns of EC2 images as json-stream

    # lsaws ec2 images -c image_id,creation_date -o js

    {"image_id":"ami-0245e6197bf3138b4","creation_date":"2023-01-19T12:03:38.000Z"}
    {"image_id":"ami-0bc3f58a172118416","creation_date":"2023-01-20T09:37:32.000Z"}
    {"image_id":"ami-07e71a1fdf49957a8","creation_date":"2023-02-01T02:06:29.000Z"}

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lsaws project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zed-0xff/lsaws/blob/master/CODE_OF_CONDUCT.md).
