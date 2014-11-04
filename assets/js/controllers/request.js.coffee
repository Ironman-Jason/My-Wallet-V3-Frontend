@RequestCtrl = ($scope, Wallet, MyWallet, $modalInstance, $log, $timeout, request, $stateParams, $translate) ->
  $scope.accounts = Wallet.accounts
  
  $scope.alerts = Wallet.alerts
  
  $scope.fields = {to: null, amount: "0"}
  
  
  
  $scope.closeAlert = (alert) ->
    Wallet.closeAlert(alert)
    
  if request == undefined || request == null  
    # Managed by this controller, amount in BTC:
    $scope.fields = {to: null, amount: "0"}  
    # Managed by Wallet service, amounts in Satoshi, has payment information:
    $scope.paymentRequest = null 
  
  $scope.close = () ->
    Wallet.clearAlerts()
    $modalInstance.dismiss ""
    
  $scope.save = () ->
    Wallet.clearAlerts()
    $modalInstance.dismiss ""
    
  $scope.cancel = () ->
    if $scope.paymentRequest
      index = $scope.accounts.indexOf($scope.fields.to)
      address = $scope.paymentRequest.address
      if Wallet.cancelPaymentRequest(index, address)
        $scope.paymentRequest = null 
      else
        $translate("PAYMENT_REQUEST_CANNOT_CANCEL").then (translation) ->
          Wallet.displayError(translation)
    
    if $scope.mockTimer != undefined
      $timeout.cancel($scope.mockTimer) 
      
    Wallet.clearAlerts()  
    $modalInstance.dismiss ""
    
  $scope.accept = () ->
    Wallet.acceptPaymentRequest($scope.accounts.indexOf($scope.fields.to), $scope.paymentRequest.address)
    
    if $scope.mockTimer != undefined
      $timeout.cancel($scope.mockTimer)
    
    Wallet.clearAlerts()
    $modalInstance.dismiss ""
  
  #################################
  #           Private             #
  #################################
  
  # Set initial form values:
  $scope.$watchCollection "accounts", () ->
    if $scope.fields.to == null && $scope.accounts.length > 0
      if request 
        # Open an existing request
        $scope.paymentRequest = request
                
        $scope.fields = {amount: angular.copy(request.amount).divide(100000000).format("0.[00000000]") }
        $scope.fields.to = $scope.accounts[request.account]
      else
        # Making a new request; default to current or first account:
        if $stateParams.accountIndex == undefined || $stateParams.accountIndex == null || $stateParams.accountIndex == ""
          $scope.fields.to = $scope.accounts[0]
        else 
          $scope.fields.to = $scope.accounts[parseInt($stateParams.accountIndex)]
          
      $scope.listenerForPayment = $scope.$watch "paymentRequest.paid", (val,before) ->
        if val != 0 && before != val && $scope.paymentRequest
          if val == $scope.paymentRequest.amount
            $modalInstance.dismiss ""
        
          else if val > 0 && val < $scope.paymentRequest.amount
            # Mock pays the remainder after 10 seconds
            if MyWallet.mockShouldReceiveNewTransaction != undefined
              $scope.mockTimer = $timeout((->
                MyWallet.mockShouldReceiveNewTransaction($scope.paymentRequest.address, "1Q9abeFt9drSYS1XjwMjR51uFH2csh86iC" , $scope.paymentRequest.amount - 100000000, "")
              ), 10000)
      
  $scope.$watch "fields.to", () ->
    $scope.formIsValid = $scope.validate()
    # TODO: warn user if they try to change this after a request has been created
        
  $scope.$watch "fields.amount", (newValue, oldValue) ->
    $scope.formIsValid = $scope.validate()
    
    if $scope.paymentRequest == null && $scope.formIsValid
      idx = $scope.accounts.indexOf($scope.fields.to)
      amount = parseInt(numeral($scope.fields.amount).multiply(100000000).format("1"))

      $scope.paymentRequest =  Wallet.generatePaymentRequestForAccount(idx, amount)

    if $scope.paymentRequest && $scope.formIsValid
      if oldValue isnt newValue && numeral(newValue) > 0
        idx = $scope.accounts.indexOf($scope.fields.to)
        amount = parseInt(numeral($scope.fields.amount).multiply(100000000).format("1"))
        Wallet.updatePaymentRequest(idx, $scope.paymentRequest.address, amount)
        
      $scope.paymentRequest.URL = "bitcoin:" + $scope.paymentRequest.address + "?amount=" + numeral($scope.paymentRequest.amount).divide(100000000)
        
      if MyWallet.mockShouldReceiveNewTransaction != undefined && request == undefined
        # Check if MyWallet is a mock or the real thing. The mock will simulate payment 
        # after 10 seconds of inactivity. Refactor if this breaks any of the
        # request controller spects.
        
      
        if $scope.mockTimer == undefined || $timeout.cancel($scope.mockTimer)                
          $scope.mockTimer = $timeout((->
            MyWallet.mockShouldReceiveNewTransaction($scope.paymentRequest.address, "1Q9abeFt9drSYS1XjwMjR51uFH2csh86iC" ,parseInt(numeral(100000000).format("1")), "")
          ), 10000)  
        


  $scope.validate = () ->
    return false if $scope.fields.to == null
    return false if parseFloat($scope.fields.amount) == 0.0
    
    return true
  
