pragma solidity ^0.4.18;

import {HelperLib} from "./HelperLib.sol";

contract ChainList {

  // custom types
  struct Article {
    uint id;
    address seller;
    address buyer;
    string amount;
    string description;
    uint price;
    uint periodFrom;
    uint periodTo;
    uint createdAt;
  }

  // custom types
  struct User {
    address account;
    string username;
  }

  // state variables
  mapping(uint => Article) public articles;
  mapping(address => User) public users;

  mapping(address => uint) balances;

  constructor() public {
    balances[tx.origin] = 100;
    users[tx.origin] = User(tx.origin, 'Account1');
  }

  uint articleCounter;

  // events
  event LogSellArticle(
    uint indexed _id,
    address indexed _seller,
    string _amount,
    uint _price,
    uint _periodFrom,
    uint _periodTo
  );

  event LogBuyArticle(
    uint indexed _id,
    address indexed _seller,
    address indexed _buyer,
    string _amount,
    uint _price
  );

  event LogPeriodCheck(
    bool valid,
    uint periodTo
  );

  event LogUsers(
    User users
  );

  event LogBalances(
    address indexed _seller,
    uint balanceSeller,
    address indexed _buyer,
    uint balanceBuyer
  );

  // sell an article
  function sellArticle(string amount, string _description, uint _price, uint _periodFrom, uint _periodTo) public {
    // a new article
    articleCounter++;
    uint createdAt = now;
    // store this article
    articles[articleCounter] = Article(
      articleCounter,
      msg.sender,
      0x0,
      amount,
      _description,
      _price,
      _periodFrom,
      _periodTo,
      createdAt
    );

    bool isValid = (now * 1000) > _periodTo ? false : true;
    emit LogPeriodCheck(isValid, now);

    users[msg.sender] = User(msg.sender, HelperLib.strConcat('User', HelperLib.uint2str(articleCounter)));

    emit LogSellArticle(articleCounter, msg.sender, amount, _price, _periodFrom, _periodTo);
    //    emit LogUsers(users[msg.sender]);
  }

  // fetch the number of articles in the contract
  function getNumberOfArticles() public view returns (uint) {
    return articleCounter;
  }

  // fetch and return all article IDs for products
  function getArticlesProducts() public view returns (uint[]) {
    // prepare output array
    uint[] memory articleIds = new uint[](articleCounter);

    uint numberOfArticles = 0;
    // iterate over articles
    for (uint i = 1; i <= articleCounter; i++) {
      // keep the ID if the article is still for sale
      articleIds[numberOfArticles] = articles[i].id;
      numberOfArticles++;
    }

    // copy the articleIds array into a smaller array
    uint[] memory artProducts = new uint[](numberOfArticles);
    for (uint j = 0; j < numberOfArticles; j++) {
      artProducts[j] = articleIds[j];
    }
    return artProducts;
  }

  // buy an article
  function buyArticle(uint _id) payable public {

    require(articleCounter > 0);

    // we check that the article exists
    require(_id > 0 && _id <= articleCounter);

    // we retrieve the article
    Article storage article = articles[_id];

    // we check that the article has not been sold yet
    require(article.buyer == 0x0);

    // we don't allow the seller to buy his own article
    require(msg.sender != article.seller);

    // we check that the value sent corresponds to the price of the article
    require(msg.value == article.price);

    // we check the availability period if expired or not
    require(((now * 1000) > article.periodTo ? false : true));

    // keep buyer's information
    article.buyer = msg.sender;

    // the buyer can pay the seller
    article.seller.transfer(msg.value);

    // trigger the event
    emit LogBuyArticle(_id, article.seller, article.buyer, article.amount, article.price);
  }

}
