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


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lsaws project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zed-0xff/lsaws/blob/master/CODE_OF_CONDUCT.md).
