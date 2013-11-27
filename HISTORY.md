## 2.0.1 (2013-11-25)

* Include Resque::Helpers for [breaking change in resque 1.25][resque125] - [jsanders][jsanders] [Pull Request][pull13], [mcfiredrill][mcfiredrill] [Pull Request][pull12]

## 2.0.0 (2012-12-04)

* Use redis setex to expire metadata from Pascal Brogle - [broglep-koubachi][broglep-koubachi] [Pull Request][pull9]
* setex require redis 2+, hence the major version bump

## 1.0.3 (2011-02-10)

* Document and test Metadata#save from Kurt Werle - [kwerle][kwerle] [Pull Request][pull3]
* Metadata#seconds_enqueued and #seconds_processing are more precise from [Steve Howell][showell]

## 1.0.2 (2010-11-03)

* Use a more random default meta_id with SHA1 from Cory Forsyth - [bantic][bantic] [Pull Request][pull2]

## 1.0.1 (2010-09-10)

* Add lib/resque-meta.rb for convenient requiring
* Doc fixes from Jeffrey Chupp - [semanticart][semanticart] [Pull Request][pull1]
* Depend more strictly on resque (>= 1.8, < 2.0)

## 1.0.0 (2010-06-04)

* Initial release

[bantic]: https://github.com/bantic
[showell]: http://librelist.com/browser//resque/2010/12/8/recording-time-in-queue-and-time-to-process/#1de6433232ac1264286feeed1f8f219e
[semanticart]: https://github.com/semanticart
[kwerle]: https://github.com/kwerle
[broglep-koubachi]: https://github.com/broglep-koubachi
[pull1]: https://github.com/lmarlow/resque-meta/pull/1
[pull2]: https://github.com/lmarlow/resque-meta/pull/2
[pull3]: https://github.com/lmarlow/resque-meta/pull/3
[pull9]: https://github.com/lmarlow/resque-meta/pull/9
[resque125]: https://github.com/resque/resque/issues/1150
[jsanders]: https://github.com/jsanders
[mcfiredrill]: https://github.com/mcfiredrill
[pull12]: https://github.com/lmarlow/resque-meta/pull/12
[pull13]: https://github.com/lmarlow/resque-meta/pull/13
