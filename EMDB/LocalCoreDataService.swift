import Foundation
import CoreData

class LocalCoreDataService {
    
    let remoteMovieService = RemoteiTunesMovieService()
    let stack = CoreDataStack.sharedInstance
    
    func searchMovies(byTerm: String, remoteHandler: @escaping ([Movie]?) -> Void) {
            remoteMovieService.searchMovies(byTerm: byTerm) { (movies) in
                if let movies = movies {
                    
                    var modelMovies = [Movie]()
                    for movie in movies {
                        let modelMovie = Movie(id: movie["id"], title: movie["title"], order: nil, summary: movie["summary"], image: movie["image"], category: movie["category"], director: movie["director"])
                            modelMovies.append(modelMovie)
                    }
                    
                    remoteHandler(modelMovies)
                } else {
                    print("Error calling REST service")
                    remoteHandler(nil)
                }
        }
    }
    
    func getTopMovies(localHandler: ([Movie]?) -> Void, remoteHandler: @escaping ([Movie]?) -> Void) {
        
        localHandler(self.queryTopMovies())
        remoteMovieService.getTopMovies { (movies) in
            if let movies = movies {
                self.markAllMoviesAsUnsync()
                
                var order = 1
                
                for movieDictionary in movies {
                    if let movie = self.getMovieById(id: movieDictionary["id"]!, favourite: false) {
                        //Update the movie in Core Data with the movie from iTunes
                        self.updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
                    } else {
                        //Add the movie from iTunes to Core Data
                        self.isertMovie(movieDictionary: movieDictionary, order: order)
                    }
                    
                    order += 1
                }
                
                //Deleting non favourite movies
                self.removeOldNonFavouriteMovies()
                
                remoteHandler(self.queryTopMovies())
                
            } else {
                remoteHandler(nil)
            }
        }
    }
    
    func queryTopMovies() -> [Movie]? {
        
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "favourite=\(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            var movies = [Movie]()
            for managedMovie in fetchedMovies {
                movies.append(managedMovie.mappedObject())
            }
            return movies
        } catch {
            print("Error getting top movies from Core Data")
            return nil
        }
    }
    
    func markAllMoviesAsUnsync() {
        
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "favourite=\(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            for managedMovie in fetchedMovies {
                managedMovie.sync = false
            }
            try context.save()
        } catch {
            print("Error updating top movies from Core Data")
        }
    }
    
    func getMovieById(id: String, favourite: Bool) -> MovieManaged? {
        
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "id=\(id) and favourite=\(favourite)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            if fetchedMovies.count > 0 {
                return fetchedMovies.last
            } else {
                return nil
            }
        } catch {
            print("Error getting movie from Core Data")
            return nil
        }
    }
    
    func isertMovie(movieDictionary: [String:String], order: Int) {
        let context = stack.persistentContainer.viewContext
        let movie = MovieManaged(context: context)
        
        movie.id = movieDictionary["id"]
        
        self.updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
        
    }
    
    func updateMovie(movieDictionary: [String:String], movie: MovieManaged, order: Int) {
        let context = stack.persistentContainer.viewContext
        
        movie.title = movieDictionary["title"]
        movie.order = Int16(order)
        movie.summary = movieDictionary["summary"]
        movie.sync = true
        movie.category = movieDictionary["category"]
        movie.director = movieDictionary["director"]
        movie.favourite = false
        movie.image = movieDictionary["image"]
        
        do {
            try context.save()
        } catch {
            print("Error updating Core Data")
        }
    }
    
    func removeOldNonFavouriteMovies() {
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        
        let predicate = NSPredicate(format: "favourite=\(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            for movie in fetchedMovies {
                if !movie.sync {
                    context.delete(movie)
                }
                
                try context.save()
            }
        } catch {
            print("Error deleting non sync movies from Core Data")
        }

    }
    
    func getFavouriteMovies() -> [Movie]? {
    
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
    
        let predicate = NSPredicate(format: "favourite=\(true)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            
            var movies : [Movie] = [Movie]()
            for managedMovie in fetchedMovies {
                movies.append(managedMovie.mappedObject())
            }
            
            return movies
            
        } catch {
            print("Error getting favourites movies")
            return nil
        }
    }
    
    func isMovieFavourite(movie: Movie) -> Bool {
        if let _ = getMovieById(id: movie.id!, favourite: true) {
            return true
        } else {
            return false
        }
    }
    
    func toogleFavourite(movie: Movie) {
        
        let context = stack.persistentContainer.viewContext
        
        if let exists = getMovieById(id: movie.id!, favourite: true) {
            context.delete(exists)
        } else {
            
            let favourite = MovieManaged(context: context)
            favourite.id = movie.id
            favourite.title = movie.title
            favourite.summary = movie.summary
            favourite.category = movie.category
            favourite.director = movie.director
            favourite.image = movie.image
            favourite.favourite = true
            
            do {
                try context.save()
            } catch {
                print("Error setting movie as favourite in Core Data")
            }
        }
        
        updateFavouritesBadge()
    }
    
    func updateFavouritesBadge() {
        if let totalFavourites = getFavouriteMovies()?.count {
            let notificationBadggeFavourites = Notification(name: Notification.Name("updateFavouritesBadgeNotificaction"), object: totalFavourites, userInfo: nil)
            NotificationCenter.default.post(notificationBadggeFavourites)
        }
    }
}
