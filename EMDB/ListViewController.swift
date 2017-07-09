import UIKit
import Kingfisher

class ListViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView : UICollectionView!
    @IBOutlet weak var searchBar : UISearchBar!
    
    var movies : [Movie] = [Movie]()
    var collectionViewPading : CGFloat = 0
    let refresh = UIRefreshControl()
    let dataProvider = LocalCoreDataService()
    
    var tapGesture : UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        searchBar.delegate = self
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        
        loadData()
        refresh.addTarget(self, action: #selector(loadData), for: UIControlEvents.valueChanged)
        collectionView.refreshControl?.tintColor = UIColor.white
        collectionView.refreshControl = refresh
        setCollectionViewPadding()
    }
    
    func setCollectionViewPadding() {
        let screenWidth = self.view.frame.width
        collectionViewPading = (screenWidth - (3 * 113))/4
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: collectionViewPading, left: collectionViewPading, bottom: collectionViewPading, right: collectionViewPading)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionViewPading
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = movies[indexPath.row]
        
        self.configureCell(cell, withMovie: movie)
        
        return cell
    }
    
    func configureCell(_ cell: MovieCell, withMovie movie: Movie) {
        if let imageData = movie.image {
            cell.movieImage.kf.setImage(with: ImageResource(downloadURL: URL(string: imageData)!), placeholder: #imageLiteral(resourceName: "img-loading"), options: nil, progressBlock: nil, completionHandler: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 113, height: 170)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.addGestureRecognizer(self.tapGesture)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            //Searching
            loadData()
        }
    }
    
    func hideKeyboard() {
        self.searchBar.resignFirstResponder()
        self.view.removeGestureRecognizer(self.tapGesture)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let term = searchBar.text {
            dataProvider.searchMovies(byTerm: term, remoteHandler: { (movies) in
                if let movies =  movies {
                    self.movies = movies
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        self.searchBar.resignFirstResponder()
                    }
                }
            })
        }
    }
    
    func loadData() {
        dataProvider.getTopMovies(localHandler: { (movies) in
            if let movies =  movies {
                self.movies = movies
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                print("No records saved in Core Data")
            }
        }, remoteHandler: {movies in
            if let movies =  movies {
                self.movies = movies
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.refresh.endRefreshing()
                }
            }
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
            if let indexPathSelected = collectionView.indexPathsForSelectedItems?.last {
                let selectedMovie = movies[indexPathSelected.row]
                let detailVC = segue.destination as! MovieViewController
                detailVC.movie = selectedMovie
            }
            
            hideKeyboard()
        }
    }
}
