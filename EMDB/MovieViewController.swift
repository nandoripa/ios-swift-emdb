import UIKit
import Kingfisher

class MovieViewController: UIViewController {
    
    @IBOutlet weak var btnFavourite: UIButton!
    @IBOutlet weak var movieImage: UIImageView!
    @IBOutlet weak var movieSummary: UITextView!
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var movieCategory: UILabel!
    @IBOutlet weak var movieDirector: UILabel!
    
    let dataProvider = LocalCoreDataService()
    var movie : Movie?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let movie = self.movie {
            
            if let image = movie.image {
                movieImage.kf.setImage(with: ImageResource(downloadURL: URL(string: image)!))
            }
            
            movieTitle.text = movie.title
            self.title = movie.title
            movieSummary.text = movie.summary
            movieCategory.text = movie.category
            movieDirector.text = movie.director
            
            configureFavouriteButton()
        }
    }
    
    @IBAction func btnFavouritePressed(_ sender: UIButton) {
        
        if let movie = self.movie {
            dataProvider.toogleFavourite(movie: movie)
            configureFavouriteButton()
        }
    }

    func configureFavouriteButton() {
        if let movie = self.movie {
            if dataProvider.isMovieFavourite(movie: movie) {
                btnFavourite.setTitle("Quiero verla", for: .normal)
                btnFavourite.setBackgroundImage(#imageLiteral(resourceName: "btn-on"), for: .normal)
            } else {
                btnFavourite.setTitle("No me interesa", for: .normal)
                btnFavourite.setBackgroundImage(#imageLiteral(resourceName: "btn-off"), for: .normal)
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        movieSummary.scrollRangeToVisible(NSMakeRange(0,0))
    }
}
