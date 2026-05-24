@IsTest
private class AccountRatingFlowTest {

    @IsTest
    static void testHotRating() {
        Account acc = new Account(Name = 'Hot Account', AnnualRevenue = 1500000);
        insert acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Hot', acc.Rating, 'Expected Hot for AnnualRevenue > 1M');
    }

    @IsTest
    static void testWarmRating() {
        Account acc = new Account(Name = 'Warm Account', AnnualRevenue = 500000);
        insert acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Warm', acc.Rating, 'Expected Warm for AnnualRevenue > 100K and <= 1M');
    }

    @IsTest
    static void testColdRating() {
        Account acc = new Account(Name = 'Cold Account', AnnualRevenue = 50000);
        insert acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Cold', acc.Rating, 'Expected Cold for AnnualRevenue <= 100K');
    }

    @IsTest
    static void testNullRevenueColdRating() {
        Account acc = new Account(Name = 'Null Revenue Account');
        insert acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Cold', acc.Rating, 'Expected Cold for null AnnualRevenue');
    }

    @IsTest
    static void testUpdateChangesRating() {
        Account acc = new Account(Name = 'Update Test Account', AnnualRevenue = 50000);
        insert acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Cold', acc.Rating, 'Expected Cold before update');

        acc.AnnualRevenue = 2000000;
        update acc;
        acc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Hot', acc.Rating, 'Expected Hot after update to AnnualRevenue > 1M');
    }

    @IsTest
    static void testBulkInsertAndUpdate() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Account ' + i, AnnualRevenue = 2000000));
        }
        insert accounts;

        Map<Id, Account> inserted = new Map<Id, Account>([SELECT Rating FROM Account WHERE Id IN :accounts]);
        for (Account a : inserted.values()) {
            System.assertEquals('Hot', a.Rating, 'Expected Hot for bulk insert');
        }

        for (Account a : accounts) {
            a.AnnualRevenue = 500;
        }
        update accounts;

        List<Account> updated = [SELECT Rating FROM Account WHERE Id IN :accounts];
        for (Account a : updated) {
            System.assertEquals('Cold', a.Rating, 'Expected Cold after bulk update to low revenue');
        }
    }
}
