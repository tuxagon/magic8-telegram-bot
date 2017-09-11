# Magic 8-Ball Telegram Bot

The `Magic8Bot` class has several methods that allow for running the bot, but the `Magic8Bot#run` method is the best way because it will leverage telegram's long-polling to retrieve updates based on messages.

The bot looks for `/shake <question>` where `<question>` is some text that must end with a `?`
