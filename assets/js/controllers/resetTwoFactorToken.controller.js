angular
  .module('walletApp')
  .controller('ResetTwoFactorTokenCtrl', ResetTwoFactorTokenCtrl);

// Wallet is injected to ensure it's lazy-load before this controller is
// initialized. Otherwise $rootScope.rootUrl will be incorrect.
function ResetTwoFactorTokenCtrl ($scope, WalletTokenEndpoints, $stateParams, $state, Alerts, $translate, AngularHelper, Wallet) {
  Alerts.clear();

  const success = (obj) => {
    $scope.checkingToken = false;

    $state.go('public.login-uid', { uid: obj.guid }).then(() => {
      Alerts.displayResetTwoFactor(obj.message);
    });

    AngularHelper.$safeApply();
  };

  const error = (res) => {
    $scope.checkingToken = false;
    $state.go('public.login-no-uid');
    Alerts.displayError(res.error, true);
    AngularHelper.$safeApply();
  };

  $scope.checkingToken = true;

  WalletTokenEndpoints.resetTwoFactor($stateParams.token).then(success).catch(error);
}
