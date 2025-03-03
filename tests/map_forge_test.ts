import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

Clarinet.test({
  name: "Cannot create itinerary with empty locations",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test Title"),
        types.utf8("Test desc"),
        types.uint(100),
        types.list([]),
        types.utf8("Details")
      ], deployer.address)
    ]);

    block.receipts[0].result.expectErr().expectUint(107);
  },
});

Clarinet.test({
  name: "Cannot create itinerary with price exceeding maximum",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test Title"),
        types.utf8("Test desc"),
        types.uint(1000000001),
        types.list([types.utf8("Location 1")]),
        types.utf8("Details")
      ], deployer.address)
    ]);

    block.receipts[0].result.expectErr().expectUint(106);
  },
});

// [Previous withdrawal test remains unchanged]
