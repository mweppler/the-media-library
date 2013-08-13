app.controller('moviesController', function($scope, $http) {
  $scope.filterForGenre  = null;
  $scope.genresService   = '/api/v1/movies/genres.json';
  $scope.genres          = [];
  $scope.keyword         = null;
  $scope.movie           = {};
  $scope.movieService    = '/api/v1/movie/:id.json';
  $scope.movies          = [];
  $scope.moviesService   = '/api/v1/movies.json';
  $scope.orderDirections = ['Ascending', 'Descending'];
  $scope.orderField      = 'Title';
  $scope.orderFields     = ['Title', 'Added'];
  $scope.orderReverse    = false;

  $scope.setGenreFilter = function(_genre) {
    $scope.filterForGenre = _genre;
  };

  $scope.sortOrder = function(_movie) {
    switch ($scope.orderField) {
      case 'Title':
        return _movie.title;
        break;
      case 'Added':
        return _movie.created_at;
        break;
      default:
        return false;
        break;
    }
    return false;
  };

  $scope.init = function() {
    $http.get($scope.moviesService).success(function(_data) {
      angular.forEach(_data, function(_media, index) {
        var movieExists = false;
        angular.forEach($scope.movies, function(_movie, index) {
          if (_media.id == _movie.id) {
            movieExists = true;
          }
        });
        if (movieExists === false) {
          $scope.movies.push(_media);
        }
      });
      $scope.movies.sort();
    }).error(function(error) {
      console.log('error: ' + error);
    });

    $http.get($scope.genreService).success(function(_data) {
      $scope.genres = _data.genres;
    }).error(function(_error) {
      console.log('error: ' + _error);
    });
  };
});

app.filter('genreFilter', function() {
  return function(_input, _genre) {
    if (typeof _genre == 'undefined' || _genre == null) {
      return _input;
    } else {
      var filteredGenres = [];
      for (var a = 0; a < _input.length; a++){
        for (var b = 0; b < _input[a].genres.length; b++){
          if(_input[a].genres[b] == _genre) {
            filteredGenres.push(_input[a]);
          }
        }
      }
      return filteredGenres;
    }
  };
});
