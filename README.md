# cyng93's scripts

Most of the scripts are based on sh, so it "should" works on various platform.


## How to use it
- Append following lines in your scripts
```sh
[ -f "/tmp/.Common.sh" ] && true \
    || curl -s https://raw.githubusercontent.com/cyng93/scripts/master/CommonFunc.sh > /tmp/.CommonFunc.sh
source /tmp/.CommonFunc.sh
```

- `CommonFunc.sh --list-all` to show all available functions.


## License
Copyright © 2017, [NG CHING YI](https://github.com/cyng93). Released under the MIT license.
