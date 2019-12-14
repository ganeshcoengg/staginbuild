describe('To do login to Connect Plus', function() {
	 var originalTimeout;

    beforeEach(function() {
        originalTimeout = jasmine.DEFAULT_TIMEOUT_INTERVAL;
        jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000000;
    });

    afterEach(function() {
      jasmine.DEFAULT_TIMEOUT_INTERVAL = originalTimeout;
    });
  it('should be able to login', function() {

	browser.waitForAngularEnabled(false);
    browser.driver.manage().window().maximize();
	browser.driver.get('http://xyzsiteName.co.in/ap/formLogin.aspx');
	
	browser.driver.findElement(by.id('txtUserName')).sendKeys('userName');
    browser.driver.findElement(by.id('txtPsswrd')).sendKeys('password');
	browser.driver.sleep(10000);
	browser.driver.findElement(by.id('userEntry_imgLogin')).click();
	browser.driver.sleep(10000);
	browser.driver.findElement(by.css('#cphPageContent_blstTrnsctn > li:nth-child(2) > a')).click();
	browser.driver.sleep(10000);
	//userEntry_imgLogin
	browser.driver.findElement(by.id('cphPageContent_cphQueryPanelContent_ucPblshFtreCntrl_ddlPlan')).sendKeys('buttonName');	
	browser.driver.findElement(by.id('cphPageContent_cphQueryPanelContent_ucPblshFtreCntrl_lnkFetch')).click();
	browser.driver.sleep(10000);
    browser.driver.findElement(by.id('cphPageContent_cphQueryPanelContent_ucPblshFtreCntrl_lnkPblshForAdminUsers')).click()
	
	browser.driver.findElement(by.id('lnkLogout')).click()
	browser.driver.sleep(10000);
    });
});