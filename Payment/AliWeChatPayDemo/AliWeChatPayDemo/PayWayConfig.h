#ifndef PayWayConfig_h
#define PayWayConfig_h

#pragma mark ----- 支付宝 -----

/*
 *商户的唯一的parnter和seller。
 *签约后，支付宝会为每个商户分配一个唯一的 parnter 和 seller。
 */
#define PartnerID @"xxxxxxx"
#define SellerID  @"xxxxxxx"

//商户私钥，自助生成
#define PartnerPrivKey @"xxxxxxxx"


#pragma mark ----- 微信支付 -----

// appID
#define __WXappID @"xxxxxx"

// appSecret
#define __WXappSecret @"xxxxxxx"

//商户号，填写商户对应参数
#define __WXmchID @"xxxxx"

//商户API密钥，填写相应参数
#define __WXpaySignKey @"xxxxxx"

#pragma mark ----- 银联支付 -----

#define __UnionPayEnviromental  @"00"  // @"01" 测试   @"00" 正式
#endif
