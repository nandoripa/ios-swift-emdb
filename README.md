# ios-swift-emdb

The EMDb project is an iOS app with Swift 3 that loads the top movies list from spanish iTunes Store. You can view detailed information about the movies an mark a movies you want to watch.

Movies you mark as you want to watch, are showed on another list. If movie you want to watch is not in the top iTunes movies list, you can use the search field to find it on iTunes.

The project use the next libraries and components from iOS.

- TabBar and Navigation controllers
- Collection and Stack views
- Core Data (the movies you get fro  iTunes are stored on Core Data as cache. You can use the app in offline mode)
- Alamofire library to make calls to iTunes API.
- SwiftyJSON to parse the JSON data returns by iTunes API.
- Kingfisher library to download an cache movies covers.
