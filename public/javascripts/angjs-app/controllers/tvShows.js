app.controller('tvShowsController', function($scope, $http) {
  $scope.filterForGenre  = null;
  $scope.filterForShow   = null;
  $scope.genresService   = '/api/v1/tv-shows/genres.json';
  $scope.genres          = [];
  $scope.keyword         = null;
  $scope.orderDirections = ['Ascending', 'Descending'];
  $scope.orderField      = 'Title';
  $scope.orderFields     = ['Title', 'Added'];
  $scope.orderReverse    = false;
  $scope.showsService    = '/api/v1/tv-shows/shows.json';
  $scope.shows           = [];
  $scope.tvShow          = {};
  $scope.tvShowService   = '/api/v1/tv-show/:id.json';
  $scope.tvShows         = [];
  $scope.tvShowsService  = '/api/v1/tv-shows.json';

  $scope.setGenreFilter = function(_genre) {
    $scope.filterForGenre = _genre;
  };

  $scope.setShowFilter = function(_show) {
    $scope.filterForShow = _show;
  };

  $scope.sortOrder = function(_tvShow) {
    switch ($scope.orderField) {
      case 'Title':
        return _tvShow.title;
        break;
      case 'Added':
        return _tvShow.created_at;
        break;
      default:
        return false;
        break;
    }
    return false;
  };

  $scope.init = function() {
    $http.get($scope.tvShowsService).success(function(_data) {
      angular.forEach(_data, function(_media, _index) {
        var tvShowExists = false;
        angular.forEach($scope.tvShows, function(_tvShow, _index) {
          if (_media.id == _tvShow.id) {
            tvShowExists = true;
          }
        });
        if (tvShowExists === false) {
          $scope.tvShows.push(_media);
        }
      });
      $scope.tvShows.sort();
    }).error(function(_error) {
      console.log('error: ' + _error);
    });

    $http.get($scope.genresService).success(function(_data) {
      $scope.genres = _data.genres;
    }).error(function(_error) {
      console.log('error: ' + _error);
    });

    $http.get($scope.showsService).success(function(_data) {
      $scope.shows = _data.shows;
    }).error(function(_error) {
      console.log('error: ' + _error);
    });
  };
});

//app.filter('genreFilter', function() {
  //return function(input, genre) {
    //if (typeof genre == 'undefined' || genre == null) {
      //return input;
    //} else {
      //var filteredGenres = [];
      //for (var a = 0; a < input.length; a++){
        //for (var b = 0; b < input[a].genres.length; b++){
          //if(input[a].genres[b] == genre) {
            //filteredGenres.push(input[a]);
          //}
        //}
      //}
      //return filteredGenres;
    //}
  //};
//});

app.filter('showFilter', function() {
  return function(_input, _show) {
    if (typeof _show == 'undefined' || _show == null) {
      return _input;
    } else {
      var filteredShows = [];
      for (var a = 0; a < _input.length; a++){
        if(_input[a].show == _show) {
          filteredShows.push(_input[a]);
        }
      }
      return filteredShows;
    }
  };
});
