@IsTest
private class OpportunityIsHighValueFlowTest {

    private static Account testAccount;

    private static Account getAccount() {
        if (testAccount == null) {
            testAccount = new Account(Name = 'Test Account');
            insert testAccount;
        }
        return testAccount;
    }

    private static Opportunity buildOpp(String name, Decimal amount) {
        Opportunity opp = new Opportunity(
            Name = name,
            AccountId = getAccount().Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        if (amount != null) {
            opp.Amount = amount;
        }
        return opp;
    }

    @IsTest
    static void testCreateAtExactThreshold() {
        Opportunity opp = buildOpp('At Threshold', 100000);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.IsHighValue__c, 'Amount = $100k should be high value');
    }

    @IsTest
    static void testCreateAboveThreshold() {
        Opportunity opp = buildOpp('Above Threshold', 150000);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.IsHighValue__c, 'Amount > $100k should be high value');
    }

    @IsTest
    static void testCreateBelowThreshold() {
        Opportunity opp = buildOpp('Below Threshold', 50000);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'Amount < $100k should not be high value');
    }

    @IsTest
    static void testCreateJustBelowThreshold() {
        Opportunity opp = buildOpp('Just Below', 99999.99);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'Amount $99,999.99 should not be high value');
    }

    @IsTest
    static void testCreateNullAmount() {
        Opportunity opp = buildOpp('Null Amount', null);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'Null Amount should default to not high value');
    }

    @IsTest
    static void testCreateZeroAmount() {
        Opportunity opp = buildOpp('Zero Amount', 0);
        insert opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'Amount = $0 should not be high value');
    }

    @IsTest
    static void testUpdateBelowToAboveThreshold() {
        Opportunity opp = buildOpp('Update Up', 50000);
        insert opp;
        opp = [SELECT Id, IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'Pre-update should be false');

        opp.Amount = 100000;
        update opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.IsHighValue__c, 'After update to $100k should flip to true');
    }

    @IsTest
    static void testUpdateAboveToBelowThreshold() {
        Opportunity opp = buildOpp('Update Down', 200000);
        insert opp;
        opp = [SELECT Id, IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, opp.IsHighValue__c, 'Pre-update should be true');

        opp.Amount = 50000;
        update opp;
        opp = [SELECT IsHighValue__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(false, opp.IsHighValue__c, 'After update to $50k should flip to false');
    }

    @IsTest
    static void testBulkInsert200Records() {
        Account acc = getAccount();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = (Math.mod(i, 2) == 0) ? 150000 : 50000
            );
            opps.add(opp);
        }
        insert opps;

        List<Opportunity> inserted = [SELECT Amount, IsHighValue__c FROM Opportunity WHERE Id IN :opps];
        System.assertEquals(200, inserted.size(), 'All 200 records inserted');
        for (Opportunity o : inserted) {
            Boolean expected = (o.Amount >= 100000);
            System.assertEquals(expected, o.IsHighValue__c,
                'Record with Amount ' + o.Amount + ' has wrong IsHighValue__c');
        }
    }
}
