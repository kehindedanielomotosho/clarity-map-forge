import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create new itinerary",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const title = "Paris Adventure";
    const description = "A weekend in Paris";
    const price = 100;
    const locations = ["Eiffel Tower", "Louvre", "Notre Dame"];
    const details = "Detailed guide for Paris";

    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii(title),
        types.utf8(description),
        types.uint(price),
        types.list(locations.map(l => types.utf8(l))),
        types.utf8(details)
      ], deployer.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(0);
  },
});

Clarinet.test({
  name: "Can purchase and access itinerary",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // First create an itinerary
    let block = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test Itinerary"),
        types.utf8("Test Description"),
        types.uint(100),
        types.list([types.utf8("Location 1")]),
        types.utf8("Details")
      ], deployer.address)
    ]);

    // Then purchase it
    let purchaseBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'purchase-itinerary', [
        types.uint(0)
      ], buyer.address)
    ]);

    purchaseBlock.receipts[0].result.expectOk().expectBool(true);

    // Verify content access
    let contentBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'get-itinerary-content', [
        types.uint(0)
      ], buyer.address)
    ]);

    contentBlock.receipts[0].result.expectSome();
  },
});

Clarinet.test({
  name: "Can rate purchased itinerary",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    // Create and purchase itinerary
    let setupBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'create-itinerary', [
        types.ascii("Test Itinerary"),
        types.utf8("Test Description"),
        types.uint(100),
        types.list([types.utf8("Location 1")]),
        types.utf8("Details")
      ], deployer.address),
      Tx.contractCall('map_forge', 'purchase-itinerary', [
        types.uint(0)
      ], buyer.address)
    ]);

    // Submit rating
    let ratingBlock = chain.mineBlock([
      Tx.contractCall('map_forge', 'rate-itinerary', [
        types.uint(0),
        types.uint(5),
        types.utf8("Great itinerary!")
      ], buyer.address)
    ]);

    ratingBlock.receipts[0].result.expectOk().expectBool(true);
  },
});