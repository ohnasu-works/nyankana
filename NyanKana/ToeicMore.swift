import Foundation

/// Extra TOEIC questions (added for a full 200-question mock test).
extension ToeicData {
    static let part2b = """
M|Where can I find the latest sales report?|Yes, I found it.|It's on the shared drive.|Sales went up last month.|1|Where（どこ）には場所で答える。sales のくり返しに注意。|wh
W|When does the training session start?|Mr. Lee is training.|In the main hall.|At nine thirty.|2|When（いつ）には時刻で答える。|wh
M|Who will lead the project?|Probably Ms. Chen.|It's a big project.|By next Friday.|0|Who（だれ）には人で答える。|wh
W|Why was the flight canceled?|I'll book a flight.|Because of the storm.|Gate twelve.|1|Why（なぜ）には理由（Because ...）で答える。|wh
M|How long will the repairs take?|It's a long road.|About two days.|The repair shop on Main Street.|1|How long（どのくらいの期間）には期間で答える。|wh
W|How many people are coming to the dinner?|Around twenty.|It was delicious.|At the Italian restaurant.|0|How many（いくつ）には数で答える。|wh
M|Which room is the interview in?|The one at the end of the hall.|For the manager position.|I'll interview tomorrow.|0|Which（どの）には特定のものを答える。|wh
W|What time does the store close?|At eight tonight.|They sell clothes.|It's close to the station.|0|What time には時刻で答える。close（近い）の別の意味に注意。|wh
M|Where should I put these boxes?|Yes, I put them there.|They're very heavy.|Next to the copy machine.|2|Where（どこ）には場所で答える。|wh
W|Who sent this package?|Someone from the head office.|It's a large package.|Express delivery.|0|Who には人（部署・会社でもよい）で答える。|wh
M|When is the report due?|It's in my report.|Due to the rain.|Not until Thursday.|2|When には時を答える。due と due to の音のひっかけ。|wh
W|Why is the elevator out of service?|It's being inspected today.|On the third floor.|Let's take the stairs to the service desk.|0|Why には理由で答える。being inspected（点検中）が理由。|wh
M|How did the presentation go?|At two o'clock.|In Room 5.|It went very well.|2|How did ... go?（どうだった）には感想・結果で答える。|wh
W|How often do you visit the factory?|It's a big factory.|By car.|About once a month.|2|How often（どのくらいの頻度）には回数で答える。|wh
M|What's the password for the Wi-Fi?|It's written on the board.|Yes, I have one.|It's very fast.|0|直接答えず「ボードに書いてある」も自然な応答。|wh
W|Where did you buy that bag?|Last weekend.|It was a gift for my sister.|At the shop near the station.|2|Where には場所で答える。|wh
M|Who's going to pick up the clients?|At the airport.|I think Tom is.|They're arriving at noon.|1|Who には人で答える。I think ... のぼかした答えも正解。|wh
W|When did you start working here?|I work in sales.|Three years ago.|Every weekday.|1|When（過去）には過去の時で答える。|wh
M|Which supplier did we choose?|We need more supplies.|Yes, we did.|The one with the lowest price.|2|Which にはどれかを特定して答える。|wh
W|How much does the subscription cost?|I'll subscribe now.|Twelve dollars a month.|It's a magazine.|1|How much には金額で答える。|wh
M|Are you going to the conference next week?|It was a great conference.|Yes, I've already registered.|In Chicago.|1|Yes/No 疑問文。Yes のあとに具体的な説明が続く形。|yesno
W|Did you finish the budget proposal?|The budget is tight.|I'm still working on it.|It was proposed last year.|1|No を言わずに「まだやっている」と答える型。|yesno
M|Have you met the new manager?|She manages the team.|Not yet, but I will tomorrow.|I'll meet you there.|1|Not yet（まだ）は Have you ...? への定番の答え。|yesno
W|Is the printer working again?|Yes, the technician fixed it.|It's on the desk.|I'll print it now.|0|Yes のあとに理由。print のくり返しに注意。|yesno
M|Do you have time to review this document?|Sure, give me ten minutes.|A three-page document.|It was reviewed yesterday.|0|Do you have time ...? には Sure などで応じる。|yesno
W|Is there a pharmacy near here?|There's one across the street.|I need some medicine.|It's near the end of the month.|0|場所を具体的に答える。near のくり返しに注意。|yesno
M|Will the shipment arrive on time?|It should be here by noon.|By ship.|Yes, it's time to go.|0|Yes を言わずに「正午には着くはず」と答える型。|yesno
W|Has the client signed the contract?|Sign here, please.|A one-year contract.|She's reviewing it now.|2|まだ署名していないことを「今確認中」で表している。|yesno
M|Can I use your stapler?|It's a new staple.|Sure, here you go.|I can't use it.|1|依頼・許可の Can I ...? には Sure / Here you go。|request
W|Could you send me the meeting notes?|I noted that.|The meeting was long.|I'll e-mail them right away.|2|依頼には引き受ける答え。notes と noted の音のひっかけ。|request
M|Would you mind closing the window?|Not at all.|It's closed on Sundays.|Yes, I mind the store.|0|Would you mind ...? への「いいですよ」は Not at all。|request
W|Can you help me move these chairs?|Of course, where do they go?|I moved last year.|They're comfortable chairs.|0|依頼に応じて質問を返す形も自然。|request
M|Could you call me back this afternoon?|It's in the back.|Sure, what time is good for you?|I called him yesterday.|1|依頼に応じて時間を確認している。back の音のひっかけ。|request
W|Would you like some more coffee?|It's more expensive.|I like the café downstairs.|No, thanks. I've had enough.|2|Would you like ...?（申し出）には Thanks / No, thanks。|suggest
M|Why don't we take a short break?|Because it's short.|It broke last week.|Good idea, I'm a little tired.|2|Why don't we ...? は提案。Because で答えない。|suggest
W|Let's order lunch from the new place.|It's a nice place to live.|I ordered it yesterday.|Sounds good to me.|2|Let's ...（提案）には賛成の答え。|suggest
M|Should we reschedule the meeting?|It was a good meeting.|Yes, Friday would be better.|The schedule is on the wall.|1|Should we ...? には具体的な代案で答えている。|suggest
W|How about having the party on the rooftop?|About fifty people.|That's a great idea.|The roof needs repairs.|1|How about ...?（提案）には賛成・反対で答える。|suggest
M|Would you like me to make copies of the agenda?|That would be helpful, thanks.|The copier is broken.|I like the agenda.|0|Would you like me to ...?（申し出）にはお礼で答える。|suggest
W|Do you want to walk or take a taxi?|Let's walk. It's not far.|Yes, I want one.|I took a taxi yesterday.|0|A or B の選択疑問文。Yes/No では答えない。|choice
M|Should I send the invoice by mail or by e-mail?|E-mail is faster.|It's an invoice.|Yes, please send it.|0|選択疑問文には片方を選んで答える。|choice
W|Would you prefer the window seat or the aisle seat?|The aisle, please.|The window is open.|I prefer tea.|0|選択疑問文。片方を選ぶ。|choice
M|Is the meeting today or tomorrow?|Yes, it is.|In the meeting room.|It was moved to tomorrow.|2|選択疑問文。Yes/No では答えない。|choice
W|Do you need the large boxes or the small ones?|Either is fine.|Yes, I need them.|They're very heavy.|0|「どちらでもいい」も選択疑問文の正解パターン。|choice
M|The copier is out of paper again.|It's a good copy.|I'll get some from the supply room.|The paper is due today.|1|報告（平叙文）には対応を述べる応答が正解。|statement
W|I can't find my keys anywhere.|Yes, I found it.|The key to success.|Did you check your desk drawer?|2|困りごとの報告には提案や質問で返す。|statement
M|The client wants to change the delivery date.|What date does she prefer?|It was delivered yesterday.|I'll change my clothes.|0|平叙文には質問を返す応答も正解。|statement
W|The new software is much faster than the old one.|I've noticed that too.|It was faster yesterday.|It's soft and comfortable.|0|感想には同意で返す。soft の音のひっかけ。|statement
M|We're running out of time.|Let's skip the last item then.|I run every morning.|It's half past three.|0|「時間がない」には対応策で返す。|statement
W|You're going to the trade show, aren't you?|I showed it to him.|It's a trade secret.|Yes, I'm leaving on Monday.|2|付加疑問文は普通の Yes/No 疑問文と同じように答える。|tag
M|The budget meeting has been postponed, hasn't it?|I posted it yesterday.|Yes, until next week.|The budget is too low.|1|付加疑問文。Yes のあとに具体的な情報。|tag
W|Isn't Mr. Kim supposed to be here today?|He's here on the map.|He called in sick this morning.|I suppose so.|1|否定疑問文も普通の疑問文と同じように内容で答える。|yesno
M|Didn't you order more envelopes last week?|The envelope is white.|They haven't arrived yet.|Yes, it's in order.|1|否定疑問文。注文したがまだ届かない、と内容で答える。|yesno
W|Where's the nearest bus stop?|The bus was late.|It stops at every station.|Just around the corner.|2|Where には場所で答える。|wh
M|When will the renovations be finished?|The building is old.|Yes, they're finished.|By the end of next month.|2|When には時を答える。|wh
W|Who left this umbrella here?|It might be Sarah's.|Leave it by the door.|It's raining hard.|0|Who にはだれかを推測する答えも正解。|wh
M|Why did the price go up?|Twenty percent off.|The cost of materials increased.|It went up the stairs.|1|Why には理由で答える。|wh
W|How do I get to the convention center?|About three thousand people.|It's a large center.|Take the subway to Central Station.|2|How do I get to ...?（行き方）には交通手段で答える。|wh
M|Which of these designs do you like best?|The blue one looks great.|Yes, I like it.|I designed it myself.|0|Which には選んで答える。|wh
W|What did the customer complain about?|Let me complain to him.|She's a regular customer.|The delivery was late.|2|What には内容で答える。|wh
M|Where are we holding the year-end party?|We haven't decided yet.|At the end of the year.|It was a fun party.|0|「まだ決まっていない」は Where にも When にも使える定番の正解。|wh
W|How long have you lived in this city?|For about ten years.|It's a long street.|I live with my family.|0|How long have you ...? には期間で答える。|wh
M|Who's responsible for ordering supplies?|That's Brian's job.|Yes, I'm responsible.|The supplies are in the closet.|0|Who には人で答える。|wh
W|When can you start the new assignment?|It's a difficult assignment.|I started it last week.|As soon as I finish this report.|2|When に「〜したらすぐ」と条件で答える型。|wh
M|Would you like to join us for lunch?|I joined the team last year.|The lunch was good.|I'd love to, but I have a meeting.|2|誘いを断るときは理由を添える。|suggest
W|Could you show me how to use this machine?|It's a washing machine.|I'll show it tomorrow at the show.|Sure, it's quite simple.|2|依頼には引き受ける答え。|request
M|Do you know when the next train leaves?|I know the conductor.|In about fifteen minutes.|It left the station.|1|Do you know when ...? は時を答える間接疑問。|yesno
W|Is this seat taken?|It's a comfortable seat.|I'll take it to the office.|No, go ahead.|2|Is this seat taken?（空いていますか）には No, go ahead（どうぞ）。|yesno
M|Shall I book a meeting room for tomorrow?|I read that book.|Yes, please. Room A if possible.|It's tomorrow morning.|1|Shall I ...?（申し出）には Yes, please。book（予約する）と book（本）のひっかけ。|suggest
W|I think the projector isn't working.|Let me call the IT department.|It's a new projector.|The project is working well.|0|問題の報告には対応で返す。projector と project の音のひっかけ。|statement
M|The client loved our proposal.|I'll propose it tomorrow.|She's a new client.|That's great news.|2|良い知らせには喜ぶ応答。|statement
W|Haven't you finished the inventory yet?|I'm almost done.|Yes, it's finished in red.|It's in the inventory.|0|否定疑問文。「もうすぐ終わる」と内容で答える。|yesno
M|Can we discuss this over lunch?|Sure, how about noon?|We discussed it yesterday.|Lunch is on the table.|0|提案に応じて時間を提案し返す。|request
W|Who should I ask about my paycheck?|I'll ask him later.|It was paid on Friday.|Someone in the payroll office.|2|Who には人・部署で答える。|wh
"""
    static let part3b = """
M: Hi, Lisa. Do you know if the conference room on the fifth floor is free this afternoon?
W: I think the marketing team booked it until three. Why?
M: I need a place to interview a job candidate at two.
W: You could use the small meeting room next to my office. Nobody's using it today.
Q: What does the man want to do this afternoon?|Interview a job applicant|Attend a marketing meeting|Repair a projector|Move to a new office|0|I need a place to interview a job candidate（面接の場所が必要）と言っている。|detail
Q: Who is using the conference room?|The sales team|The marketing team|A job candidate|The woman's manager|1|the marketing team booked it（マーケティングチームが予約）とある。|detail
Q: What does the woman suggest?|Using a different room|Calling the manager|Canceling the interview|Changing the time|0|You could use the small meeting room（小さい会議室を使えば）と提案している。|suggest
---
W: Good morning, Riverside Dental Clinic. How can I help you?
M: Hello, I have an appointment on Thursday at ten, but something came up at work. Could I change it to next week?
W: Let me see. We have an opening on Tuesday at four in the afternoon.
M: That works. Thank you.
Q: Why is the man calling?|To cancel a delivery|To report a problem with a bill|To reschedule an appointment|To ask about prices|2|appointment を来週に変えたいと言っている。電話の目的は前半に出る。|purpose
Q: Why can't the man come on Thursday?|He will be traveling.|The clinic is closed.|He has a work commitment.|He is sick.|2|something came up at work（仕事の用事ができた）と言っている。|detail
Q: When will the man most likely visit the clinic?|On Friday morning|On Thursday morning|On Wednesday afternoon|On Tuesday afternoon|3|Tuesday at four in the afternoon に That works と答えている。|inference
---
M: Excuse me, I bought this coffee maker here last week, but it stopped working yesterday.
W: I'm sorry to hear that. Do you have your receipt?
M: Yes, here it is.
W: Thank you. Since it's still under warranty, we can give you a new one, or you can get your money back.
M: I'll take a new one, please.
Q: Where most likely are the speakers?|At a coffee shop|At an electronics store|At a repair center|At a bank|1|bought this coffee maker here（ここで買った）とあるので家電店。|gist
Q: What does the woman ask for?|A credit card|A product code|An e-mail address|A receipt|3|Do you have your receipt?（レシートはありますか）と聞いている。|detail
Q: What will the man most likely receive?|A full refund|A discount coupon|A free repair|A replacement product|3|I'll take a new one（新しいものにします）と答えている。|next
---
W: Tom, how is the preparation for the product launch going?
M: Pretty well. The brochures were printed yesterday, but the banners won't be ready until Friday.
W: The event is on Saturday, so that's cutting it close.
M: I know. I'll ask the printing company if they can deliver them a day earlier.
Q: What are the speakers preparing for?|A company anniversary|A product launch|A trade fair abroad|A staff training|1|the product launch（新製品の発表）の準備について話している。|gist
Q: What is the woman concerned about?|The timing of a delivery|The design of a brochure|The cost of printing|The location of the event|0|that's cutting it close（ぎりぎりだ）と心配している。|inference
Q: What will the man do next?|Visit the venue|Contact a printing company|Change the event date|Design a new banner|1|I'll ask the printing company（印刷会社に聞いてみる）と言っている。|next
---
M: Hi, I'd like to open a savings account. What do I need to bring?
W: You'll need a photo ID and proof of address, like a utility bill.
M: I have my driver's license with me, but not a bill.
W: That's fine. You can start the application today and bring the bill within two weeks.
Q: Where does the woman most likely work?|At a travel agency|At a bank|At a post office|At a library|1|savings account（普通預金口座）を開く話なので銀行。|gist
Q: What does the man lack?|An appointment|A pen|A photo ID|Proof of address|3|not a bill（請求書は持っていない）＝住所の証明がない。|detail
Q: What does the woman say the man can do?|Open the account online|Submit a document later|Use a different ID|Come back tomorrow|1|bring the bill within two weeks（2週間以内に持ってくればいい）と言っている。|detail
---
W: Kevin, I heard you're moving to the Singapore office next month.
M: That's right. I'll be managing the new sales team there.
W: Congratulations! Have you found a place to live yet?
M: Not yet. The company is arranging temporary housing for the first month, so I'll look for an apartment after I arrive.
Q: What will the man do next month?|Start a new business|Transfer to another office|Retire from the company|Take a vacation|1|moving to the Singapore office（シンガポール事務所へ異動）とある。|gist
Q: What will the man's new role be?|Office designer|Real estate agent|Sales team manager|Human resources director|2|managing the new sales team（新しい営業チームの管理）と言っている。|detail
Q: According to the man, what is the company doing?|Hiring more staff|Opening a store|Paying for his flight|Providing temporary housing|3|The company is arranging temporary housing（会社が仮住まいを手配）と言っている。|detail
---
M: Excuse me, does this bus go to the city museum?
W: No, you need the number 12. This is the number 21.
M: Oh, I see. Where can I catch the 12?
W: The stop is right across the street, in front of the bakery. It comes every ten minutes.
Q: Where most likely are the speakers?|At a bakery|At a bus stop|At a museum|At a train station|1|bus の路線について話しているのでバス停。|gist
Q: What mistake did the man make?|He lost his ticket.|He went to the wrong museum.|He missed his stop.|He was waiting for the wrong bus.|3|12番ではなく21番のバスだった。数字のひっかけに注意。|inference
Q: What does the woman say about the number 12 bus?|It is very crowded.|It stops in front of the museum.|It comes every ten minutes.|It is not running today.|2|It comes every ten minutes（10分ごとに来る）と言っている。|detail
---
W: Hi, I'm calling from Brightway Office Supplies. We received your order for twenty desk chairs.
M: Yes, we need them for our new office.
W: Unfortunately, the black model is sold out. We have the same chair in gray. Would that be acceptable?
M: Gray is fine, as long as they can be delivered by the 15th.
Q: Why is the woman calling?|To report that an item is unavailable|To offer a discount|To confirm a payment|To change a delivery address|0|the black model is sold out（黒は売り切れ）と伝えている。|purpose
Q: What did the man order?|Office desks|Computers|Desk chairs|Paper|2|twenty desk chairs（いす20脚）とある。|detail
Q: What condition does the man mention?|The size|The delivery date|The price|The color|1|as long as they can be delivered by the 15th（15日までに届くなら）と条件をつけている。|detail
---
M: Sarah, could you take a look at this e-mail before I send it to the client?
W: Sure. Hmm, I think you should mention the new pricing in the first paragraph.
M: Good point. They'll probably want to know that first.
W: Also, don't forget to attach the updated catalog.
Q: What does the man ask the woman to do?|Change the prices|Review an e-mail|Call a client|Update a catalog|1|take a look at this e-mail（メールを見てほしい）と頼んでいる。|detail
Q: What does the woman suggest?|Sending the e-mail later|Lowering the price|Moving some information to the beginning|Calling the client instead|2|mention the new pricing in the first paragraph（最初の段落に入れる）と提案。|suggest
Q: What does the woman remind the man to do?|Book a meeting|Attach a file|Print a copy|Sign a contract|1|don't forget to attach the updated catalog（カタログの添付を忘れずに）。|detail
---
W: Welcome to Harbor View Restaurant. Do you have a reservation?
M: No, we don't. Is there a table for four available?
W: I'm afraid it'll be about a thirty-minute wait. You're welcome to wait at the bar.
M: That's fine. Could we sit by the window when a table opens up?
Q: What does the man ask for?|The check|A take-out menu|A room upstairs|A table for four|3|a table for four（4人用のテーブル）を求めている。|detail
Q: What does the woman suggest?|Coming back tomorrow|Making a reservation online|Waiting at the bar|Trying another restaurant|2|You're welcome to wait at the bar（バーで待てる）と提案。|suggest
Q: What does the man request?|A quiet area|A seat by the window|A discount|A children's menu|1|sit by the window（窓際の席）を頼んでいる。|detail
---
M: Hi, Anna. I'm organizing the team-building trip, and I need to know if you're joining.
W: When is it again?
M: Saturday the 20th. We're going hiking and then having a barbecue.
W: Oh, I have a family event that morning, but I can join for the barbecue in the afternoon.
Q: What is the man organizing?|A team trip|A family party|A sales meeting|A product launch|0|team-building trip（チームの親睦旅行）を計画している。|gist
Q: What will happen on the trip?|A museum visit|A cooking class|A boat tour|Hiking and a barbecue|3|going hiking and then having a barbecue とある。|detail
Q: What does the woman say she will do?|Drive the team|Skip the event entirely|Join part of the event|Organize the food|2|午後のバーベキューだけ参加すると言っている。|inference
---
W: Excuse me, I'm looking for a book called "Modern Marketing."
M: Let me check our system. It looks like we have one copy, but it's checked out until Monday.
W: Can I reserve it?
M: Yes. I just need your library card. We'll send you an e-mail when it's returned.
Q: Where are the speakers?|At a bookstore|At a printing shop|At a library|At a school office|2|checked out / library card から図書館。|gist
Q: What problem does the man mention?|The system is down.|The book is currently borrowed.|The book is damaged.|The book is out of print.|1|checked out until Monday（月曜まで貸し出し中）。|detail
Q: How will the woman be notified?|By phone|By letter|By text message|By e-mail|3|We'll send you an e-mail（メールで知らせる）と言っている。|detail
---
M: Have you seen the results of the customer survey?
W: Yes. Most customers like our new menu, but many said the wait time is too long.
M: Maybe we should hire another cook for the weekends.
W: That's a good idea. I'll talk to the owner about the budget tomorrow.
Q: What are the speakers discussing?|A staff schedule|Survey results|A new recipe|A restaurant opening|1|customer survey の結果について話している。|gist
Q: What did customers complain about?|Long waiting times|Rude staff|High prices|Small portions|0|the wait time is too long（待ち時間が長い）とある。|detail
Q: What will the woman do tomorrow?|Hire a cook|Change the menu|Send a survey|Talk to the owner|3|I'll talk to the owner（オーナーと話す）と言っている。|next
---
W: Mark, the projector in Room B isn't turning on. I have a presentation in twenty minutes.
M: I'll come and check it. It might be the power cable.
W: Thanks. If we can't fix it, is there another room I can use?
M: Room D has a projector, and I think it's free right now.
Q: What problem does the woman have?|Her laptop is broken.|A projector does not work.|A room is double-booked.|She lost her presentation file.|1|the projector ... isn't turning on（プロジェクターがつかない）。|detail
Q: Who most likely is the man?|A sales manager|A client|A receptionist|A technician|3|機器を確認しに来るので技術担当と推測できる。|inference
Q: What does the man say about Room D?|It is available.|It is being cleaned.|It needs a key.|It is too small.|0|I think it's free right now（今空いていると思う）。|detail
---
M: Hello, I'm calling about the apartment listed on your Web site, the two-bedroom on Oak Street.
W: Yes, it's still available. Would you like to see it?
M: I would. Is Thursday evening possible?
W: I can show it at six. Please bring a copy of your ID.
Q: What is the man interested in?|Renting an apartment|Hiring a cleaner|Selling a house|Buying a car|0|apartment listed on your Web site（サイトの物件）について電話している。|gist
Q: Where did the man learn about the apartment?|From a friend|On a Web site|On a sign|In a newspaper|1|listed on your Web site とある。|detail
Q: What does the woman ask the man to bring?|A reference letter|An identification document|A floor plan|A deposit|1|bring a copy of your ID（身分証のコピー）。|detail
---
W: Daniel, I think we need to update the employee handbook.
M: I agree. A lot of the policies have changed since it was written.
W: Could you list the sections that need changes? I'll ask the legal team to review them.
M: Sure. I'll have the list ready by the end of the week.
Q: What do the speakers want to update?|A training video|An employee handbook|A product catalog|A Web site|1|the employee handbook（従業員ハンドブック）を更新したい。|gist
Q: What will the legal team do?|Print the handbook|Review some sections|Hire new staff|Write a new policy|1|ask the legal team to review them（法務に確認してもらう）。|detail
Q: When will the man finish the list?|Next month|By the end of the week|Tomorrow morning|Today|1|by the end of the week（週末までに）と言っている。|detail
---
M: Welcome to Sunrise Hotel. Are you checking in?
W: Yes, I have a reservation under the name Martinez. Is it possible to get a room with a view of the ocean?
M: Let me check. Yes, there's one available, but it's an extra twenty dollars per night.
W: That's fine. Also, what time is breakfast served?
Q: What does the woman request?|A late checkout|An extra bed|A room with an ocean view|A taxi|2|a room with a view of the ocean（海の見える部屋）。|detail
Q: What does the man mention?|A full hotel|A free breakfast|A broken elevator|An additional charge|3|an extra twenty dollars per night（1泊20ドルの追加料金）。|detail
Q: What does the woman ask about?|Breakfast time|Internet access|The pool|Parking|0|what time is breakfast served?（朝食は何時）と聞いている。|detail
---
W: Hi, I'd like to sign up for the weekend photography class.
M: Great. The beginner class starts on the 5th. Do you have your own camera?
W: Yes, but it's a bit old.
M: That's no problem. Any camera will work. The fee is eighty dollars, and you can pay at the first class.
Q: What does the woman want to do?|Register for a class|Repair a camera|Buy a camera|Sell some photos|0|sign up for the weekend photography class（写真教室に申し込む）。|gist
Q: What does the man ask the woman?|Where she lives|If she owns a camera|How she heard about the class|When she is free|1|Do you have your own camera?（カメラを持っているか）。|detail
Q: According to the man, how can the woman pay?|Online|By bank transfer|In installments|At the first class|3|you can pay at the first class（初回の授業で払える）。|detail
---
M: Jessica, the delivery truck just arrived, but half of the boxes are damaged.
W: Oh no. Did you take any pictures?
M: Yes, I took several.
W: Good. Please send them to the shipping company and ask for replacements. I'll let the store managers know there might be a delay.
Q: What problem are the speakers discussing?|A late truck|Damaged goods|A wrong address|A missing invoice|1|half of the boxes are damaged（半分の箱が破損）。|gist
Q: What does the woman ask the man to do?|Return the truck|Call a store manager|Send photos to a company|Repair the boxes|2|send them to the shipping company（写真を配送会社へ送る）。|detail
Q: What will the woman do?|Drive to the warehouse|Order new boxes|Take more pictures|Inform store managers|3|I'll let the store managers know（店長に知らせる）と言っている。|next
---
W: Peter, are you coming to the workshop on data analysis tomorrow?
M: I'd like to, but I have a client call at ten. What time does it start?
W: Nine thirty, and it runs until noon. But they're recording it, so you can watch it later.
M: Great. Could you send me the link when it's available?
Q: What event are the speakers discussing?|A company party|A workshop|A client call|A job interview|1|the workshop on data analysis（データ分析の研修）。|gist
Q: Why might the man miss the event?|He is on vacation.|He is not invited.|He has a doctor's appointment.|He has a client call.|3|I have a client call at ten（10時に顧客との電話）。|detail
Q: What does the man ask the woman to do?|Reschedule the call|Send him a link|Take notes|Record the event|1|send me the link（リンクを送って）と頼んでいる。|detail
---
M: Hi, I'm here to pick up some photos I ordered online. My name is Chris Walker.
W: Let me find them. Here they are, twenty prints and one poster.
M: Actually, I ordered two posters.
W: Oh, I'm sorry. The second one must still be printing. It should be ready in about fifteen minutes. Would you like to wait?
Q: Why is the man at the store?|To buy a camera|To return a poster|To take passport photos|To pick up an order|3|pick up some photos I ordered（注文した写真の受け取り）。|purpose
Q: What problem does the man point out?|The price is wrong.|An item is missing.|The prints are the wrong size.|The photos are blurry.|1|two posters を頼んだのに1枚しかない。|detail
Q: What does the woman say about the second poster?|It will be mailed.|It was lost.|It costs extra.|It will be ready soon.|3|ready in about fifteen minutes（15分ほどでできる）。|detail
"""
    static let part4b = """
N: Good morning, everyone, and welcome to Greenline Manufacturing. My name is Laura, and I'll be your guide for today's factory tour. Before we begin, please put on the safety glasses and helmets on the table. The tour will take about one hour. We'll start with the assembly line and finish in the testing area. Photography is not allowed inside the building, so please put your phones away.
Q: Who most likely is the speaker?|A factory customer|A tour guide|A safety inspector|A new employee|1|I'll be your guide for today's factory tour（工場見学の案内役）と言っている。|gist
Q: What are listeners asked to do first?|Turn off the lights|Put on safety equipment|Watch a video|Sign a form|1|put on the safety glasses and helmets（保護メガネとヘルメットを着用）。|detail
Q: What is not allowed during the tour?|Eating food|Taking photos|Touching products|Asking questions|1|Photography is not allowed（写真撮影は禁止）。|detail
---
N: Hi, this is Rachel from Pinewood Interiors. I'm calling about the curtains you ordered for your living room. The fabric you chose is currently out of stock, and the supplier says it won't be available for another three weeks. We have a similar fabric in a slightly lighter color that we could use instead. If you'd like to see a sample, I can bring it to your home on Friday. Please call me back at 555-0193.
Q: What is the purpose of the message?|To offer a job|To request a payment|To report a supply problem|To confirm an installation|2|the fabric ... is currently out of stock（生地が在庫切れ）と伝えている。|purpose
Q: What does the speaker suggest?|Visiting the store|Canceling the order|Using a different fabric|Waiting a month|2|We have a similar fabric ... that we could use instead（似た生地を代わりに）。|suggest
Q: What does the speaker offer to do on Friday?|Measure the windows|Bring a sample|Give a refund|Install the curtains|1|I can bring it to your home on Friday（金曜にサンプルを持っていく）。|detail
---
N: Thank you for calling Westfield Public Library. Our hours are Monday through Friday, nine A.M. to eight P.M., and Saturday, ten A.M. to five P.M. The library is closed on Sundays. Please note that the library will be closed next Monday for a national holiday. To renew a book, press one. To speak with a librarian, please stay on the line.
Q: Where does the message come from?|A bookstore|A museum|A library|A school|2|Westfield Public Library と名乗っている。|gist
Q: Why will the facility be closed next Monday?|Because of a holiday|Because of bad weather|Because of repairs|Because of a staff meeting|0|closed next Monday for a national holiday（祝日のため休館）。|detail
Q: What should listeners do to renew a book?|Press one|Visit the Web site|Send an e-mail|Stay on the line|0|To renew a book, press one（延長は1番）。|detail
---
N: Good afternoon, shoppers. For the next thirty minutes only, all fresh fruit in our produce section is twenty percent off. That includes apples, oranges, and our popular strawberries. Also, don't forget to visit the bakery at the back of the store, where we're offering free samples of our new whole-grain bread. Thank you for shopping at FreshMart.
Q: Where is the announcement being made?|In a supermarket|In a farm|In a bakery school|In a restaurant|0|shoppers / produce section / FreshMart からスーパー。|gist
Q: How long will the discount last?|Thirty minutes|One week|One hour|All day|0|For the next thirty minutes only（30分間だけ）。数字に注意。|detail
Q: What is available at the bakery?|Gift baskets|Cooking classes|Discount coupons|Free samples|3|free samples of our new whole-grain bread（新しいパンの試食）。|detail
---
N: Welcome to this month's staff meeting. First, I'm happy to announce that our sales increased by fifteen percent compared to last quarter. Much of that success came from our new online store. However, customer service calls have also increased, so we're hiring two more customer service representatives. Next, Mr. Ito will explain the new vacation request system.
Q: What is the main purpose of the talk?|To introduce a new product|To share company updates|To train new employees|To announce a retirement|1|staff meeting で売上や採用などの報告をしている。|gist
Q: According to the speaker, what contributed to the sales increase?|An online store|A TV commercial|Lower prices|A new branch|0|came from our new online store（ネットショップのおかげ）。|detail
Q: What will Mr. Ito talk about next?|Customer complaints|A vacation request system|A new office|Sales targets|1|explain the new vacation request system（休暇申請の新システム）。|next
---
N: And now for the weather. It'll be cloudy this morning, with rain moving in by early afternoon. The rain will be heavy at times, so drivers should be careful on the roads during the evening commute. The good news is that the weekend looks sunny and warm, perfect for the Riverside Music Festival on Saturday.
Q: What kind of weather is expected this afternoon?|Rain|Sunshine|Strong wind|Snow|0|rain moving in by early afternoon（午後には雨）。|detail
Q: Who does the speaker give advice to?|Drivers|Pilots|Farmers|Students|0|drivers should be careful（ドライバーは注意）。|detail
Q: What event will take place on Saturday?|A music festival|A sports game|A marathon|A food fair|0|the Riverside Music Festival on Saturday。|detail
---
N: Hello, Mr. Grant. This is Emily Chen from the human resources department. I'm calling to let you know that we'd like to offer you the position of accounting assistant. Congratulations! Your start date will be the first of next month. I'll send you an e-mail with the contract and some forms. Please sign and return them by Friday.
Q: Why is the speaker calling?|To ask for a reference|To schedule an interview|To offer a job|To explain a bill|2|we'd like to offer you the position（採用のお知らせ）。|purpose
Q: What position will the listener have?|Receptionist|Accounting assistant|HR director|Sales manager|1|the position of accounting assistant とある。|detail
Q: What should the listener do by Friday?|Return some forms|Open a bank account|Call the manager|Visit the office|0|sign and return them by Friday（金曜までに署名して返送）。|detail
---
N: Attention, all passengers on Flight 208 to Vancouver. The departure gate has been changed from gate 15 to gate 22. Boarding will begin in twenty minutes. Passengers traveling with small children or those needing special assistance are invited to board first. We apologize for the inconvenience.
Q: Where is the announcement most likely being made?|On a ship|At a hotel|At an airport|At a train station|2|Flight / gate / Boarding から空港。|gist
Q: What has changed?|The destination|The gate number|The departure time|The airline|1|gate 15 から gate 22 に変更。|detail
Q: Who will board first?|Business class passengers|Airline staff|Passengers with small children|Group travelers|2|traveling with small children ... board first（子ども連れが先）。|detail
---
N: Thank you all for coming to today's workshop on time management. Over the next two hours, we'll look at practical ways to organize your tasks and reduce stress at work. Please take one of the handouts being passed around now. Halfway through, we'll take a ten-minute break. At the end, I'll ask you to fill out a short survey about today's session.
Q: What is the topic of the workshop?|Time management|Computer skills|Customer service|Public speaking|0|today's workshop on time management とある。|gist
Q: What are listeners asked to take?|A snack|A name tag|A handout|A pen|2|take one of the handouts（資料を取って）。|detail
Q: What will listeners do at the end?|Work in groups|Complete a survey|Take a test|Watch a video|1|fill out a short survey（アンケートに記入）。|next
---
N: Hi, it's Mike from the IT department. Just a reminder that our e-mail system will be updated tonight from ten P.M. to two A.M. During that time, you won't be able to send or receive messages. Please save any important drafts before you leave today. If you have any problems tomorrow morning, call the help desk at extension 400.
Q: What will happen tonight?|The office will be cleaned.|A system will be updated.|The building will be closed.|A party will be held.|1|our e-mail system will be updated tonight（今夜メールシステムを更新）。|gist
Q: What are listeners asked to do?|Save their drafts|Leave early|Change their passwords|Turn off their computers|0|save any important drafts（下書きを保存）。|detail
Q: How can listeners get help?|By asking a manager|By calling an extension|By visiting a Web site|By sending an e-mail|1|call the help desk at extension 400（内線400）。|detail
---
N: Welcome aboard the Lakeview Ferry. Our trip to Blue Island will take about forty-five minutes. Snacks and drinks are available at the café on the lower deck. For your safety, please stay seated while the ferry is docking. Life jackets are located under every seat. We hope you enjoy the view of the lake.
Q: Where most likely are the listeners?|On a bus|On an airplane|On a train|On a boat|3|Ferry / deck / docking から船。|gist
Q: Where can listeners buy food?|On the island|On the lower deck|At the front of the ferry|At the ticket office|1|café on the lower deck（下のデッキのカフェ）。|detail
Q: What are listeners asked to do while the ferry is docking?|Collect their bags|Stay seated|Go to the upper deck|Put on life jackets|1|please stay seated while the ferry is docking。|detail
---
N: Good evening, and welcome to tonight's awards dinner. We're here to honor the employees who made outstanding contributions this year. Before we present the awards, I'd like to thank Kingsley Catering for this wonderful meal. Our first award, for Best New Employee, goes to someone who has been with us for only eight months but has already won three new clients.
Q: What is the purpose of the event?|To celebrate a retirement|To open a restaurant|To recognize employees|To welcome clients|2|honor the employees who made outstanding contributions（優秀な社員の表彰）。|gist
Q: Who does the speaker thank?|The company president|A catering company|The clients|The award winners|1|thank Kingsley Catering（ケータリング会社に感謝）。|detail
Q: What does the speaker say about the first award winner?|The person is retiring.|The person has brought in new clients.|The person has worked there for ten years.|The person won last year.|1|already won three new clients（新規顧客を3社獲得）。|detail
---
N: This message is for all residents of Maple Apartments. The water will be turned off on Wednesday from nine A.M. to three P.M. while workers replace the main pipes. We recommend that you store some water before then. We're sorry for the inconvenience. If you have questions, please contact the building manager's office on the first floor.
Q: Who is the message for?|Hotel guests|Construction workers|Office employees|Apartment residents|3|all residents of Maple Apartments（マンションの住民）。|gist
Q: Why will the water be turned off?|Because of a storm|To save money|For a safety inspection|For pipe replacement|3|workers replace the main pipes（配管の交換）。|detail
Q: What does the speaker recommend?|Leaving the building|Storing water in advance|Checking the pipes|Calling a plumber|1|store some water before then（事前に水をためておく）。|suggest
---
N: Welcome to the City Art Museum. Our new exhibition, "Light and Color," features over one hundred paintings from the early twentieth century. The exhibition is on the second floor and will be open until the end of June. Audio guides are available at the information desk for five dollars. Please remember that food and drinks are not allowed in the galleries.
Q: What is being introduced?|A new exhibition|A painting class|A museum café|A building tour|0|Our new exhibition（新しい展示）を紹介している。|gist
Q: Where can visitors get an audio guide?|At the gift shop|On the second floor|Online|At the information desk|3|available at the information desk（案内所で）。|detail
Q: What are visitors reminded about?|Tickets are sold out.|Photos are not allowed.|Food is not allowed inside.|The museum closes early.|2|food and drinks are not allowed（飲食禁止）。|detail
---
N: Hi, Sandra. It's Victor. I'm at the client's office now, and I realized I left the presentation slides on my desk. They're in a blue folder. Could you scan them and e-mail them to me as soon as possible? The meeting starts in an hour. Thanks so much.
Q: Where is the speaker now?|At home|At an airport|At a client's office|At his desk|2|I'm at the client's office now とある。|detail
Q: What did the speaker forget?|A contract|His laptop|Some presentation slides|His phone|2|left the presentation slides on my desk（スライドを置き忘れた）。|detail
Q: What does the speaker ask Sandra to do?|Call the client|Scan and send some documents|Cancel a meeting|Bring a folder to him|1|scan them and e-mail them to me（スキャンしてメールで送って）。|detail
---
N: This is a reminder that Oakdale Fitness Center will be closed for renovations from July 1 to July 14. During this time, members can use our downtown location at no extra cost. When we reopen, you'll find new exercise machines, a larger yoga studio, and improved locker rooms. Thank you for your patience.
Q: Why will the center be closed?|Because of low membership|For renovations|For a holiday|For a private event|1|closed for renovations（改装のため）。|gist
Q: What can members do during the closure?|Pause their membership|Use another location|Get a refund|Take online classes|1|use our downtown location at no extra cost（別店舗を追加料金なしで利用）。|detail
Q: What will NOT be mentioned as new?|Locker rooms|Exercise machines|A swimming pool|A yoga studio|2|プールは言っていない。NOT 問題は消去法で。|detail
---
N: Good morning. Before we start today's sales training, I want to remind everyone that the quarterly reports are due next Friday. Please submit them through the new online system, not by e-mail. If you haven't used the system yet, Jenny from the IT team will hold a short session this afternoon at three in Room 4.
Q: What is due next Friday?|Vacation requests|Training fees|Quarterly reports|Customer surveys|2|the quarterly reports are due next Friday（四半期報告の締め切り）。|detail
Q: How should the reports be submitted?|In person|By e-mail|Through an online system|By mail|2|through the new online system, not by e-mail。not に注意。|detail
Q: What will Jenny do this afternoon?|Lead the sales training|Hold a session|Collect the reports|Fix the computers|1|Jenny ... will hold a short session（説明会を開く）。|next
---
N: Hello, this is Dr. Patel's office calling for Ms. Rivera. We received your test results, and everything looks normal. However, the doctor would like to see you for a short follow-up visit in about three months. Please call our office to schedule a time that works for you. Our number is 555-0148. Have a good day.
Q: Who is the message for?|A doctor|A pharmacist|A nurse|A patient|3|Dr. Patel's office から Ms. Rivera への連絡＝患者向け。|gist
Q: What does the speaker say about the test results?|They need to be repeated.|They are not ready.|They are normal.|They were lost.|2|everything looks normal（すべて正常）。|detail
Q: What is the listener asked to do?|Call to make an appointment|Visit the office today|Send her results|Pay a bill|0|call our office to schedule a time（予約の電話を）。|detail
"""
    static let part6b = """
P: Dear Ms. Howard,
P: Thank you for your interest in the marketing coordinator position at Lindell Foods. We were very ---(1)--- by your experience and would like to invite you for an interview. The interview will take place on Tuesday, May 12, at 10 A.M. ---(2)--- our main office on Grant Street. ---(3)--- Please reply to this e-mail to ---(4)--- that you are available.
P: Sincerely, Paul Grayson, Human Resources
Q: (1)|impress|impressed|impressive|impression|1|be impressed by（〜に感心する）。受け身の形容詞。|p6grammar
Q: (2)|for|on|at|to|2|建物・場所の一点には at。|p6grammar
Q: (3)|Our company was founded twenty years ago.|The position has already been filled.|We sell frozen foods across the country.|Please bring a copy of your résumé and a photo ID.|3|面接の案内の流れに合う「持ち物」の文を選ぶ。|p6context
Q: (4)|confirm|confirmation|confirming|confirmed|0|to のあとは動詞の原形。to confirm（確認するために）。|p6grammar
---
P: Notice to All Tenants
P: The building's fitness room will be ---(1)--- from March 1 to March 10 while new equipment is installed. During this period, tenants may use the gym at the Riverside Hotel next door ---(2)--- charge. Simply show your building key card at the front desk. ---(3)--- We are confident you will enjoy the ---(4)--- facilities.
Q: (1)|open|closed|cleaned|crowded|1|新しい機器を設置する間は「閉鎖」される。|p6vocab
Q: (2)|in|by|free of|with|2|free of charge（無料で）。決まった表現。|p6grammar
Q: (3)|Key cards cannot be replaced.|Rent will increase next year.|The new machines include treadmills and rowing machines.|The hotel restaurant is famous for its seafood.|2|「新しい設備」の具体的な説明が自然につながる。|p6context
Q: (4)|improved|improve|improvement|improving|0|名詞 facilities を修飾する形容詞（過去分詞）improved（改良された）。|p6grammar
---
P: From: Customer Service
P: To: Daniel Kim
P: Subject: Your recent order
P: Dear Mr. Kim, thank you for shopping with GreenLeaf Garden Supply. Unfortunately, the ceramic pots you ordered are ---(1)--- out of stock. We expect to receive more by June 20. ---(2)---, the rest of your order will be shipped today. ---(3)--- If you would prefer to cancel the pots and receive a refund, please let us know. We apologize for the ---(4)---.
Q: (1)|currents|currency|currently|current|2|be 動詞と形容詞句の間なので副詞 currently（現在）。|p6grammar
Q: (2)|Instead|Meanwhile|Otherwise|Therefore|1|鉢が届くまでの「その間に」残りを発送する。|p6context
Q: (3)|The pots will be sent separately when they arrive.|We hired three new employees.|Ceramic pots are easy to break.|Our store is closed on Sundays.|0|鉢がどうなるかを説明する文が流れに合う。|p6context
Q: (4)|inconvenient|convenience|convenient|inconvenience|3|the のあとは名詞。apologize for the inconvenience（ご不便をおわびする）。|p6vocab
---
P: Riverside Community Center is looking for volunteers to help with our annual book fair on October 5. Volunteers will help set up tables, sort books, and assist visitors. No experience is ---(1)---. All volunteers will receive a free T-shirt and lunch. ---(2)--- you are interested, please sign up at the front desk ---(3)--- September 25. ---(4)---
Q: (1)|necessarily|necessary|necessitate|necessity|1|be 動詞のあとの形容詞 necessary（必要な）。|p6grammar
Q: (2)|Because|If|Unless|Although|1|「もし興味があれば」申し込んでください。|p6grammar
Q: (3)|until|by|during|since|1|締め切りは by（〜までに）。until は継続。|p6grammar
Q: (4)|The center is closed on weekends.|Books are sold for one dollar each.|We look forward to working with you.|The fair was canceled last year.|2|募集のお知らせの締めくくりとして自然な文。|p6context
---
P: To: All Sales Staff
P: Starting next month, all expense reports must be submitted through our new online system. The system will make the process faster and more ---(1)---. A training session will be held on Thursday at 3 P.M. in Room 210. ---(2)--- who cannot attend can watch a recording later. ---(3)---. If you have any questions, please contact Jane in the accounting department. Thank you for your ---(4)---.
Q: (1)|accurately|accuracies|accurate|accuracy|2|faster と並ぶ形容詞 accurate（正確な）。|p6grammar
Q: (2)|This|That|These|Those|3|Those who ...（〜する人々）。|p6grammar
Q: (3)|Sales increased by ten percent last year.|Jane joined the company in 2019.|Paper forms will no longer be accepted after the 30th.|Room 210 has a new projector.|2|新しいシステムへの切り替えに関係する文。|p6context
Q: (4)|cooperate|cooperation|cooperatively|cooperative|1|your のあとは名詞 cooperation（協力）。|p6grammar
---
P: Bayview Hotel is pleased to announce the opening of our new rooftop restaurant, Skyline. The restaurant offers a ---(1)--- view of the harbor and serves fresh local seafood. Skyline is open for dinner every day from 5 P.M. to 11 P.M. and has only twenty tables. ---(2)---, reservations are strongly recommended. Hotel guests ---(3)--- a 10 percent discount on all meals. ---(4)---
Q: (1)|breathtakingly|breath|breathe|breathtaking|3|名詞 view を修飾する形容詞 breathtaking（息をのむような）。|p6grammar
Q: (2)|Instead|Therefore|However|For example|1|席が20しかない →「だから」予約を勧める。Therefore（したがって）。|p6context
Q: (3)|receiving|received|receive|to receive|2|主語 Hotel guests に対する動詞の現在形。|p6grammar
Q: (4)|The hotel has 200 rooms.|The harbor was built in 1890.|To book a table, call 555-0172 or visit our Web site.|Seafood prices rose last month.|2|予約の方法を伝える文で締めくくる。|p6context
---
P: Dear valued customer,
P: We are writing to let you know that our prices will ---(1)--- by 5 percent starting April 1. This change is ---(2)--- to rising costs for materials and shipping. We have worked hard to keep prices low for as long as possible. ---(3)--- As always, we remain ---(4)--- to providing you with the best products and service.
Q: (1)|to increase|increase|increasing|increased|1|助動詞 will のあとは原形。|p6grammar
Q: (2)|due|since|owing|because|0|be due to（〜による）。|p6grammar
Q: (3)|Shipping is free on Sundays.|Our factory is located in Ohio.|We are hiring new drivers.|Orders placed before April 1 will be charged at the current prices.|3|値上げ前の注文の扱いを説明する文が自然。|p6context
Q: (4)|committed|commitment|committing|commit|0|be committed to（〜に力を注ぐ）。|p6vocab
"""
    static let part7b = """
P: NOTICE
P: The second-floor kitchen will be closed on Friday, May 9, for cleaning. Employees may use the kitchen on the third floor. Please remove all personal items from the refrigerator by Thursday at 5 P.M. Any items left after that time will be thrown away.
Q: Why will the kitchen be closed?|For a party|For an inspection|For cleaning|For repairs|2|closed ... for cleaning（清掃のため）とある。|detail
Q: What are employees asked to do by Thursday?|Remove their items from the refrigerator|Sign a form|Clean the third-floor kitchen|Bring their own lunch|0|remove all personal items from the refrigerator by Thursday。|detail
---
P: Text message from Brian Ward, 10:42 A.M.
P: Hi Mia, the client meeting has moved from 2 P.M. to 3:30 P.M. The client's flight was delayed. Can you let the rest of the team know? Also, please book Room C instead of Room A. Room A is being used for interviews this afternoon.
Q: Why was the meeting moved?|Room A was not available.|The team was busy.|A client's flight was late.|Brian was sick.|2|The client's flight was delayed（顧客の便が遅れた）。|detail
Q: What does Brian ask Mia to do?|Cancel the meeting|Inform the team and book a room|Pick up the client|Conduct interviews|1|let the rest of the team know と Room C の予約を頼んでいる。|detail
---
P: Lakeside Running Club
P: Join us every Sunday at 7 A.M. for a group run around Lake Marion! Runners of all levels are welcome. Choose from a 5-kilometer or 10-kilometer course. Membership is free. After the run, members gather at Lakeside Café, where they receive a free coffee. Visit lakesiderunners.org to sign up.
Q: What is true about the club?|It is open to all levels.|It only offers one course.|It charges a monthly fee.|It meets every Saturday.|0|Runners of all levels are welcome とある。|detail
Q: What do members receive after the run?|A T-shirt|A discount on shoes|A medal|A free coffee|3|they receive a free coffee とある。|detail
Q: How can people join?|By visiting the lake|By signing up online|By calling the café|By sending a letter|1|Visit lakesiderunners.org to sign up（サイトで登録）。|detail
---
P: Invoice #4471 — Brightline Printing
P: Customer: Tanaka Design Studio
P: 500 business cards ............ $60.00
P: 200 color brochures ........... $240.00
P: Rush delivery fee ............. $25.00
P: Total ......................... $325.00
P: Payment is due within 30 days. A 2% discount is applied if payment is received within 10 days.
Q: What did the customer order?|Envelopes and letterheads|Business cards and brochures|Posters and banners|Books and calendars|1|business cards と color brochures。|detail
Q: Why was an extra fee charged?|For a design change|For late payment|For fast delivery|For color printing|2|Rush delivery fee（特急配送料）。|detail
Q: How can the customer reduce the total?|By using a coupon|By paying within ten days|By picking up the order|By ordering more cards|1|within 10 days の支払いで2%引き。|inference
---
P: Welcome to the Oakwood Hotel! Free Wi-Fi is available throughout the hotel. To connect, select "Oakwood-Guest" and enter your room number and last name. If you need faster Internet for video calls, you can upgrade to Premium Wi-Fi for $8 per day at the front desk. For technical support, dial 7 from your room phone.
Q: What do guests need to connect to the Wi-Fi?|Their room number and last name|A password from the front desk|A credit card|An e-mail address|0|enter your room number and last name。|detail
Q: What is suggested for video calls?|Upgrading the Internet service|Using the business center|Moving to another room|Calling the front desk|0|faster Internet for video calls ... upgrade to Premium Wi-Fi。|inference
---
P: Dear Mr. Lopez,
P: I am writing to thank you for the excellent catering service at our company's anniversary party last Saturday. The food was delicious, and your staff was very professional. Many of our guests asked for your contact information. We would like to use your service again for our holiday party in December. Could you send us a price estimate for 120 people?
P: Best regards, Helen Brooks, Event Coordinator
Q: What is the purpose of the letter?|To cancel an event|To apply for a job|To complain about a service|To express thanks and request a quote|3|感謝と、12月のパーティーの見積もり依頼。|gist
Q: What happened last Saturday?|A company anniversary party|A holiday party|A cooking class|A job fair|0|our company's anniversary party last Saturday。|detail
Q: What does Ms. Brooks ask Mr. Lopez to send?|A list of staff|A contract|A price estimate|A menu sample|2|send us a price estimate for 120 people。|detail
---
P: [Online Chat]
P: Amy Cho (9:15): Has anyone seen the new floor plan for the office move?
P: Raj Patel (9:16): Yes, I got it yesterday. Our team will be near the windows on the fourth floor.
P: Amy Cho (9:17): Great. Do we know when the movers are coming?
P: Liam Ford (9:18): Friday afternoon. We need to pack our desks by Thursday evening.
P: Amy Cho (9:19): Got it. I'll pick up boxes from the supply room today.
Q: What are the writers discussing?|A new project|An office move|A product delivery|A team lunch|1|office move（事務所の移転）について話している。|gist
Q: By when must the team pack their desks?|Friday afternoon|Today|Monday morning|Thursday evening|3|pack our desks by Thursday evening。|detail
Q: At 9:19, what does Ms. Cho mean when she writes, "Got it"?|She found her desk.|She received the floor plan.|She understands the plan.|She bought new boxes.|2|Got it は「了解した」。意図を問う問題。|intent
---
P: CITY NEWS — The Harbor Bridge will be closed to cars for three weeks starting June 1 while workers repair the road surface. Pedestrians and cyclists will still be able to use the bridge. The city recommends that drivers use the Elm Street tunnel instead. Additional buses will run during morning and evening rush hours to help reduce traffic.
Q: What will happen starting June 1?|A bridge will be closed to cars.|A tunnel will be built.|A new road will open.|Bus fares will rise.|0|closed to cars for three weeks starting June 1。|detail
Q: Who can still use the bridge?|Taxis|Delivery trucks|Buses|Pedestrians and cyclists|3|Pedestrians and cyclists will still be able to use the bridge。|detail
Q: What will the city do to reduce traffic?|Open the bridge at night|Run more buses|Lower parking fees|Close the tunnel|1|Additional buses will run（バスを増便）。|detail
---
P: JOB OPENING: Part-time Barista
P: Morning Leaf Café is looking for a friendly part-time barista to work weekend mornings. Applicants should have at least six months of experience in a café or restaurant. We offer flexible hours, free meals during shifts, and a staff discount. To apply, send your résumé to jobs@morningleaf.com by March 15.
Q: When would the barista mainly work?|Weekday evenings|Holidays only|Weekend mornings|Every night|2|work weekend mornings とある。|detail
Q: What is required?|Language skills|A university degree|A driver's license|Experience in food service|3|six months of experience in a café or restaurant。|detail
Q: What is NOT mentioned as a benefit?|Free meals|Health insurance|A staff discount|Flexible hours|1|保険は書かれていない。NOT 問題は1つずつ照合する。|detail
---
P: Memo
P: To: All Employees
P: Re: Recycling Program
P: Beginning next Monday, we will start a new recycling program. Blue bins for paper will be placed next to every printer, and green bins for plastic bottles will be placed in each kitchen. Please do not put food waste in either bin. Thank you for helping us reduce waste. — Facilities Team
Q: What is the memo about?|A kitchen renovation|A cleaning schedule|A printer upgrade|A new recycling program|3|a new recycling program を始める。|gist
Q: Where will the green bins be placed?|Next to printers|At the entrance|In the kitchens|In the parking lot|2|green bins ... in each kitchen。|detail
---
P: Thank you for purchasing the ClearView X2 camera. Before using the camera for the first time, fully charge the battery for about three hours. The camera comes with a one-year warranty. To register your product and extend the warranty to two years, visit www.clearviewcam.com within 30 days of purchase.
Q: What should be done before first use?|Register online|Charge the battery|Update the software|Clean the lens|1|fully charge the battery（充電する）。|detail
Q: How can the warranty be extended?|By buying a second camera|By returning a form by mail|By registering online within 30 days|By paying an extra fee|2|register ... within 30 days で2年に延長。|detail
---
P: Northgate Library — Summer Events
P: Children's Story Time: Tuesdays, 10 A.M.
P: Book Club for Adults: First Thursday of each month, 7 P.M.
P: Computer Basics Workshop: Saturdays, 2 P.M. (registration required)
P: All events are free. To register for the workshop, ask at the front desk or call 555-0120.
Q: Which event requires registration?|All events|Computer Basics Workshop|Book Club for Adults|Children's Story Time|1|(registration required) は Computer Basics Workshop。|detail
Q: How much do the events cost?|$5 each|Nothing|$10 per month|It depends on the event|1|All events are free。|detail
---
P: From: Maria Gonzalez
P: To: Tim Baker
P: Subject: Sales Report
P: Hi Tim, I've attached the sales report for the third quarter. Overall sales were up 8 percent, mainly because of strong online sales. However, sales at our downtown store went down. I think we should discuss this at Monday's meeting. Could you also check the numbers on page 4? I'm not sure they are correct.
Q: Why were overall sales higher?|Because of a TV advertisement|Because a new store opened|Because online sales were strong|Because prices went up|2|mainly because of strong online sales。|detail
Q: What problem does Ms. Gonzalez mention?|A missing report|A delayed meeting|Lower sales at one store|A broken computer|2|sales at our downtown store went down。|detail
Q: What does she ask Mr. Baker to do?|Write a new report|Lead the meeting|Visit the downtown store|Check some figures|3|check the numbers on page 4。|detail
---
P: Parking Permit Information
P: Employees who drive to work must display a valid parking permit on their car's dashboard. Permits are $20 per month and can be purchased from the security office on the first floor. Cars without a permit may be towed at the owner's expense. Visitors should park in the spaces marked "Guest" near the main entrance.
Q: Where can employees buy a permit?|At the security office|At the main entrance|From their manager|Online|0|purchased from the security office on the first floor。|detail
Q: What may happen to cars without a permit?|They can park in guest spaces.|They must pay $20.|They may be towed.|They will receive a warning.|2|may be towed at the owner's expense（レッカー移動）。|detail
Q: Where should visitors park?|In the security office lot|In marked guest spaces|On the street|In the employee lot|1|spaces marked "Guest" near the main entrance。|detail
---
P: Review: Rosa's Kitchen ★★★★☆
P: I had dinner at Rosa's Kitchen last Friday with my family. The pasta was fresh and the portions were large. The only problem was the noise — it was very crowded and hard to hear each other talk. I'd recommend making a reservation and going on a weekday. — Posted by Jordan M.
Q: What did the reviewer like?|The quiet atmosphere|The music|The food|The low prices|2|The pasta was fresh and the portions were large（料理）。|detail
Q: What does the reviewer suggest?|Sitting outside|Going for lunch|Visiting on a weekday|Ordering pizza|2|going on a weekday とすすめている。|detail
---
P: Announcement: Employee of the Month
P: Congratulations to Sophie Martin from the customer service team! Sophie has been chosen as Employee of the Month for October. Customers praised her patience and quick solutions. In just six months with us, she has received more positive feedback than any other team member. Sophie will receive a $100 gift card and a reserved parking space for November.
Q: Why was Ms. Martin chosen?|For her excellent customer service|For selling the most products|For training new staff|For working the longest hours|0|patience and quick solutions がほめられている。|inference
Q: How long has Ms. Martin worked at the company?|Six months|Two years|One month|One year|0|In just six months with us。|detail
Q: What will Ms. Martin receive?|A promotion|A bonus check|A trip|A gift card and a parking space|3|$100 gift card and a reserved parking space。|detail

---
P: 【文書1】Advertisement
P: Summit Office Furniture — Spring Sale! 20% off all desks and chairs from April 1 to April 15. Free delivery on orders over $500. Visit our showroom at 45 King Street or order online at summitoffice.com.
P: 【文書2】E-mail
P: To: orders@summitoffice.com / From: Alan Reed / Date: April 10
P: Hello, I'd like to order eight ergonomic chairs (regularly $80 each) for our new office. Since my order is over $500, I understand delivery will be free. We need the chairs by April 20. Could you confirm that this is possible? — Alan Reed, Reed Accounting
Q: What is being advertised?|A furniture sale|A delivery job|A new showroom|An office for rent|0|Spring Sale（春のセール）の広告。|gist
Q: Until when does the sale last?|April 1|April 15|April 30|April 20|1|from April 1 to April 15。|detail
Q: What does Mr. Reed want to buy?|Desks|Lamps|Chairs|Bookshelves|2|eight ergonomic chairs。|detail
Q: What is suggested about Mr. Reed's order?|It will receive a discount.|It must be picked up.|It is under $500.|It will be delivered on April 10.|0|4月10日の注文はセール期間内なので20%引き。2つの文書を合わせて考える。|inference
Q: What is Mr. Reed's concern?|The store location|The price of desks|The delivery date|The color of the chairs|2|We need the chairs by April 20. Could you confirm ...?|detail
---
P: 【文書1】Schedule — Global Tech Conference, Hall B
P: 9:00 Opening Speech — Dr. Karen Liu
P: 10:30 Cloud Security Trends — Mark Evans
P: 1:00 Building Better Apps — Sara Kim
P: 3:00 Panel Discussion: The Future of AI
P: 【文書2】E-mail
P: To: All attendees / From: Conference Office
P: Please note that Mark Evans's flight has been delayed, so his talk will be moved to 3:00. The panel discussion will begin at 10:30 instead. Lunch will be served in Hall C from 12:00 to 1:00.
Q: Who will give the opening speech?|Mark Evans|Dr. Karen Liu|A panel of experts|Sara Kim|1|9:00 Opening Speech — Dr. Karen Liu。|detail
Q: Why was the schedule changed?|A speaker's flight was delayed.|Lunch was moved.|A speaker canceled.|A room was unavailable.|0|Mark Evans's flight has been delayed。|detail
Q: What time will the cloud security talk begin?|3:00|10:30|1:00|9:00|0|Mark Evans の講演（Cloud Security）が3時に変更。2文書の組み合わせ。|inference
Q: What will happen at 10:30?|An opening speech|Lunch|A talk on apps|A panel discussion|3|The panel discussion will begin at 10:30 instead。|detail
Q: Where will lunch be served?|In the lobby|In Hall B|Outside|In Hall C|3|Lunch will be served in Hall C。|detail
---
P: 【文書1】Job Advertisement
P: Westbrook Bank is hiring a Customer Service Representative for its Main Street branch. Requirements: two years of customer service experience; Spanish language skills preferred. Send your résumé to hr@westbrookbank.com by June 30.
P: 【文書2】E-mail
P: To: hr@westbrookbank.com / From: Nina Alvarez / Date: June 25
P: Dear Hiring Manager, I am applying for the Customer Service Representative position. I have worked at a hotel front desk for three years and speak both English and Spanish. I have attached my résumé. I am available for an interview any weekday after 4 P.M.
P: 【文書3】E-mail
P: To: Nina Alvarez / From: Westbrook Bank HR / Date: June 27
P: Dear Ms. Alvarez, thank you for your application. We would like to invite you to an interview on July 3 at 4:30 P.M. Please bring a photo ID.
Q: What position is being advertised?|Spanish teacher|Customer service representative|Bank director|Hotel manager|1|Customer Service Representative。|detail
Q: What is suggested about Ms. Alvarez?|She meets the requirements.|She applied after the deadline.|She lives near Main Street.|She works at a bank.|0|3年の接客経験＋スペイン語で条件を満たす。文書1と2の照合。|inference
Q: Where does Ms. Alvarez currently work?|At a school|At a bank|At a hotel|At a restaurant|2|worked at a hotel front desk for three years。|detail
Q: When will the interview take place?|July 1|July 3|June 30|June 27|1|interview on July 3 at 4:30 P.M.|detail
Q: Why was the interview most likely scheduled after 4 P.M.?|Because of a holiday|Because of Ms. Alvarez's availability|Because the bank closes early|Because the manager is busy|1|available ... any weekday after 4 P.M. に合わせている。3つの文書を合わせる。|inference
---
P: 【文書1】Notice — Greenfield Apartments
P: Annual fire alarm inspections will take place on September 12 and 13. Technicians will need to enter each apartment for about 15 minutes. Floors 1–5: September 12. Floors 6–10: September 13. If you will not be home, please leave your key at the management office.
P: 【文書2】E-mail
P: To: Management Office / From: David Park, Apartment 802
P: Hello, I will be on a business trip from September 11 to 15. I'll drop off my key at your office on September 10. Please make sure it is returned to my mailbox after the inspection. Thank you.
Q: What is the purpose of the notice?|To introduce new staff|To explain a new rule for pets|To announce an inspection|To announce a rent increase|2|fire alarm inspections の告知。|gist
Q: How long will technicians be in each apartment?|Half a day|About one hour|About 15 minutes|All day|2|for about 15 minutes。|detail
Q: When will Mr. Park's apartment be inspected?|September 13|September 10|September 12|September 15|0|802号室＝8階 → Floors 6–10 は13日。2文書の組み合わせ。|inference
Q: Why will Mr. Park not be home?|He will be traveling for work.|He is on vacation.|He is moving out.|He is in the hospital.|0|on a business trip（出張）。|detail
Q: What does Mr. Park ask the office to do?|Fix his alarm|Return his key to his mailbox|Call him after the inspection|Change the inspection date|1|returned to my mailbox after the inspection。|detail
---
P: 【文書1】Web page — Coastline Bike Rentals
P: City Bike: $15 per day / Electric Bike: $35 per day / Tandem Bike: $30 per day
P: Helmets are included. Rentals over 3 days receive a 10% discount. Open daily 8 A.M. – 6 P.M.
P: 【文書2】Customer Review — posted by Grace L.
P: My husband and I rented a tandem bike for four days during our vacation. It was the perfect way to see the coast! The staff were friendly and gave us a map with the best routes. My only suggestion is that they open earlier, since we wanted to start riding before 8.
Q: What is included with every rental?|A lock|A map|A helmet|A water bottle|2|Helmets are included。|detail
Q: What type of bike did Grace L. rent?|A tandem bike|An electric bike|A city bike|A mountain bike|0|rented a tandem bike。|detail
Q: What is suggested about Grace L.'s rental?|It was free.|It was discounted.|It was canceled.|It lasted one day.|1|4日間の利用 → 3日超で10%引き。文書1と2の照合。|inference
Q: What did the staff give the customers?|A free lunch|A helmet discount|A map|A tour guide|2|gave us a map with the best routes。|detail
Q: What does Grace L. suggest?|Opening earlier|Hiring more staff|Offering more bikes|Lowering prices|0|they open earlier（もっと早く開店）を提案。|detail
---
P: 【文書1】Memo
P: To: All staff / From: Office Manager
P: Our office will switch to a new coffee supplier, BeanWorks, starting next month. The kitchen will have three kinds of coffee and two kinds of tea. Please fill out the online survey by Friday to tell us which flavors you prefer.
P: 【文書2】Survey results summary
P: Responses: 48 employees. Most popular coffee: Dark Roast (22 votes). Most popular tea: Green Tea (30 votes). Other requests: decaf coffee (9 people), oat milk (12 people).
P: 【文書3】E-mail
P: To: Office Manager / From: BeanWorks Customer Service
P: Thank you for your order. We have added Dark Roast and Green Tea to your monthly delivery. Unfortunately, we do not carry oat milk, but we can include decaf coffee at no extra charge.
Q: What is the memo mainly about?|A staff party|A new kitchen|An office move|A change of supplier|3|switch to a new coffee supplier。|gist
Q: How many employees responded to the survey?|12|30|22|48|3|Responses: 48 employees。|detail
Q: Which request was made by 12 people?|Green tea|Decaf coffee|Dark roast|Oat milk|3|oat milk (12 people)。|detail
Q: What will BeanWorks NOT provide?|Green tea|Decaf coffee|Dark roast|Oat milk|3|we do not carry oat milk。|detail
Q: What is suggested about decaf coffee?|It must be ordered separately.|It is not available.|It was the most popular choice.|It will be included without charge.|3|we can include decaf coffee at no extra charge。|inference
"""
}

extension ToeicBank {
    static let raw2 = """
pos|その会社は品質の高い製品で知られています。|그 회사는 품질 높은 제품으로 알려져 있습니다.|那家公司以高品質的產品聞名。|The company is known for its high-quality [products].|produce;productive;productively
pos|新しい受付係はとても親切に対応してくれました。|새 접수 담당자는 매우 친절하게 응대해 주었습니다.|新的接待員非常親切地接待了我們。|The new receptionist treated us very [kindly].|kind;kindness;kinder
pos|その計画には慎重な検討が必要です。|그 계획에는 신중한 검토가 필요합니다.|那個計畫需要慎重的考慮。|The plan requires [careful] consideration.|carefully;care;cares
pos|応募書類は人事部に直接提出してください。|지원 서류는 인사부에 직접 제출해 주십시오.|請將申請文件直接交給人事部。|Please submit your application [directly] to the human resources department.|direct;direction;directed
pos|彼の提案は役員会で強い支持を受けました。|그의 제안은 이사회에서 강한 지지를 받았습니다.|他的提案在董事會獲得強力支持。|His [proposal] received strong support from the board.|propose;proposed;proposing
pos|この地域の不動産価格は急速に上昇しています。|이 지역의 부동산 가격은 빠르게 오르고 있습니다.|這個地區的房價正在快速上漲。|Property prices in this area are rising [rapidly].|rapid;rapidity;more rapid
pos|全従業員は安全規則を守る責任があります。|모든 직원은 안전 규칙을 지킬 책임이 있습니다.|所有員工都有責任遵守安全規定。|All employees are [responsible] for following safety rules.|responsibility;responsibly;respond
pos|そのホテルは駅から便利な場所にあります。|그 호텔은 역에서 편리한 곳에 있습니다.|那家飯店位於離車站很方便的地方。|The hotel is [conveniently] located near the station.|convenient;convenience;conveniences
pos|顧客からの意見は製品改善に欠かせません。|고객의 의견은 제품 개선에 필수적입니다.|顧客的意見對改善產品不可或缺。|Feedback from customers is [essential] for improving our products.|essentially;essence;essentials
verb|その報告書は昨日までに提出されるべきでした。|그 보고서는 어제까지 제출되었어야 했습니다.|那份報告應該在昨天之前提交。|The report should have been [submitted] by yesterday.|submit;submitting;submits
verb|新しい工場は来年完成する予定です。|새 공장은 내년에 완공될 예정입니다.|新工廠預計明年完工。|The new factory is expected [to be completed] next year.|completing;completes;completed
verb|私たちは5年間その会社と取引をしています。|우리는 5년 동안 그 회사와 거래하고 있습니다.|我們和那家公司已經合作五年了。|We [have been doing] business with that company for five years.|do;did;are doing
verb|会議が始まったとき、彼女はまだ資料を印刷していました。|회의가 시작되었을 때 그녀는 아직 자료를 인쇄하고 있었습니다.|會議開始時，她還在列印資料。|When the meeting started, she [was still printing] the handouts.|still prints;has still printed;is still printing
verb|来週の今頃、私たちは新しい事務所で働いているでしょう。|다음 주 이맘때 우리는 새 사무실에서 일하고 있을 것입니다.|下週的這個時候，我們會在新辦公室工作。|This time next week, we [will be working] in our new office.|worked;have worked;work
verb|応募者全員がその試験を受けることを求められています。|모든 지원자는 그 시험을 보도록 요구됩니다.|所有應徵者都被要求參加那項考試。|All applicants are required [to take] the test.|taking;took;taken
verb|マネージャーは私たちに報告書を見直させました。|매니저는 우리에게 보고서를 다시 검토하게 했습니다.|經理讓我們重新檢查報告。|The manager had us [review] the report.|reviewing;reviewed;to review
verb|もし予算があれば、私たちは新しい機械を買うでしょう。|만약 예산이 있다면 우리는 새 기계를 살 것입니다.|如果有預算，我們就會買新機器。|If we had the budget, we [would buy] new equipment.|will buy;bought;buy
verb|その商品は先月から売り切れています。|그 상품은 지난달부터 품절 상태입니다.|那項商品從上個月起就賣完了。|The item [has been] sold out since last month.|is;was;will be
verb|新しい方針について話し合うことを提案します。|새 방침에 대해 논의할 것을 제안합니다.|我建議討論新的方針。|I suggest [discussing] the new policy.|to discuss;discussed;discuss of
prep|その店は午前10時から午後8時まで開いています。|그 가게는 오전 10시부터 오후 8시까지 엽니다.|那家店從上午十點營業到晚上八點。|The store is open [from] 10 A.M. to 8 P.M.|since;at;during
prep|悪天候にもかかわらず、イベントは予定どおり行われました。|악천후에도 불구하고 행사는 예정대로 진행되었습니다.|儘管天氣惡劣，活動仍照常舉行。|[Despite] the bad weather, the event was held as planned.|Although;Even;However
prep|すべての注文は3営業日以内に発送されます。|모든 주문은 영업일 기준 3일 이내에 발송됩니다.|所有訂單會在三個工作天內出貨。|All orders will be shipped [within] three business days.|until;among;through
prep|会議中は携帯電話の電源を切ってください。|회의 중에는 휴대전화 전원을 꺼 주십시오.|會議期間請關掉手機。|Please turn off your phones [during] the meeting.|while;for;since
prep|その書類は金曜日までに提出してください。|그 서류는 금요일까지 제출해 주십시오.|請在星期五之前提交那份文件。|Please hand in the documents [by] Friday.|until;on;in
prep|彼はマーケティング部の代表として会議に出席しました。|그는 마케팅부를 대표해 회의에 참석했습니다.|他代表行銷部出席了會議。|He attended the meeting [on behalf of] the marketing department.|in front of;instead;because
prep|その会社は環境に関する問題に取り組んでいます。|그 회사는 환경에 관한 문제에 대처하고 있습니다.|那家公司正在處理與環境有關的問題。|The company is dealing with issues [regarding] the environment.|regard;regarded;regards to
prep|新しい規則によると、従業員は身分証を着用しなければなりません。|새 규정에 따르면 직원은 신분증을 착용해야 합니다.|根據新規定，員工必須配戴識別證。|[According to] the new rules, employees must wear ID badges.|Because of;Instead of;In spite of
conj|会議が長引いたので、彼は電車に乗り遅れました。|회의가 길어져서 그는 기차를 놓쳤습니다.|因為會議拖太久，他錯過了火車。|He missed the train [because] the meeting ran late.|despite;so;although
conj|天気が良ければ、昼食会は屋外で行います。|날씨가 좋으면 오찬은 야외에서 합니다.|如果天氣好，午餐會將在戶外舉行。|[If] the weather is nice, the luncheon will be held outdoors.|Unless;Although;Whether
conj|料金を払わない限り、サービスは利用できません。|요금을 내지 않으면 서비스를 이용할 수 없습니다.|除非付費，否則無法使用服務。|You cannot use the service [unless] you pay the fee.|if;because;when
conj|彼女は経験が少ないけれども、すばらしい仕事をしました。|그녀는 경험이 적지만 훌륭한 일을 해냈습니다.|雖然她經驗不多，但工作做得很出色。|[Although] she has little experience, she did an excellent job.|Despite;Because;Unless
conj|製品は安いだけでなく、とても丈夫です。|제품은 저렴할 뿐만 아니라 매우 튼튼합니다.|產品不只便宜，而且非常耐用。|The product is not only cheap [but also] very durable.|and so;as well;either
conj|その仕事を受けるかどうか、まだ決めていません。|그 일을 맡을지 아직 결정하지 않았습니다.|我還沒決定是否接受那份工作。|I haven't decided [whether] to accept the job.|that;what;unless
conj|皆が聞こえるように、彼女は大きな声で話しました。|모두가 들을 수 있도록 그녀는 큰 소리로 말했습니다.|為了讓大家都聽得到，她大聲說話。|She spoke loudly [so that] everyone could hear her.|such as;in case;even if
conj|在庫がなくなるまで、割引は続きます。|재고가 떨어질 때까지 할인은 계속됩니다.|折扣會持續到庫存賣完為止。|The discount will continue [until] the stock runs out.|by;since;during
pron|あなたの部署の皆さん全員に招待状を送りました。|당신 부서의 모든 분께 초대장을 보냈습니다.|已經寄邀請函給你們部門的所有人。|We sent invitations to everyone in [your] department.|you;yours;yourself
pron|そのデザイナーは自分でウェブサイトを作りました。|그 디자이너는 직접 웹사이트를 만들었습니다.|那位設計師自己做了網站。|The designer built the Web site [herself].|her;hers;she
pron|昨日面接した応募者は、とても有能でした。|어제 면접한 지원자는 매우 유능했습니다.|昨天面試的應徵者非常能幹。|The applicant [whom] we interviewed yesterday was very capable.|which;whose;what
pron|それは私たちが去年改装した建物です。|그것은 우리가 작년에 개조한 건물입니다.|那是我們去年改裝的建築物。|That is the building [which] we renovated last year.|who;whom;whose
pron|これらの書類のどちらでも使えます。|이 서류들 중 어느 것이든 사용할 수 있습니다.|這些文件中任何一份都可以用。|You can use [either] of these forms.|both;each other;neither of
pron|ロゴが青い会社が私たちの新しい取引先です。|로고가 파란 회사가 우리의 새 거래처입니다.|那家標誌是藍色的公司是我們的新客戶。|The company [whose] logo is blue is our new client.|who;which;that's
pron|参加者はそれぞれ自分の名札をつけてください。|참가자는 각자 자기 이름표를 달아 주십시오.|每位參加者請配戴自己的名牌。|Each participant should wear [his or her] own name tag.|their self;them;they
vocab|私たちは来月、新しいサービスを開始します。|우리는 다음 달에 새 서비스를 시작합니다.|我們下個月將推出新服務。|We will [launch] a new service next month.|lunch;lend;limit
vocab|この割引は会員だけが利用できます。|이 할인은 회원만 이용할 수 있습니다.|這個折扣只有會員可以使用。|This discount is [available] only to members.|capable;possible;valuable
vocab|彼はその職の条件を満たしています。|그는 그 직책의 조건을 충족합니다.|他符合那個職位的條件。|He [meets] the requirements for the position.|makes;keeps;takes
vocab|会議は来週に延期されました。|회의는 다음 주로 연기되었습니다.|會議延到了下週。|The meeting has been [postponed] until next week.|canceled;proceeded;promoted
vocab|その企業は海外に事業を拡大する予定です。|그 기업은 해외로 사업을 확장할 예정입니다.|那家企業打算將事業擴展到海外。|The firm plans to [expand] its business overseas.|expend;expect;explain
vocab|お問い合わせには24時間以内に返信いたします。|문의에는 24시간 이내에 답변드립니다.|我們會在二十四小時內回覆您的詢問。|We will respond to your [inquiry] within 24 hours.|income;injury;instruction
vocab|この契約は来年3月に期限が切れます。|이 계약은 내년 3월에 만료됩니다.|這份合約明年三月到期。|This contract will [expire] next March.|explore;exceed;expose
vocab|会社は従業員に研修の機会を提供しています。|회사는 직원들에게 연수 기회를 제공하고 있습니다.|公司為員工提供培訓機會。|The company [provides] employees with training opportunities.|prevents;proves;protests
vocab|その建物はまもなく改装工事のため閉鎖されます。|그 건물은 곧 개조 공사로 폐쇄됩니다.|那棟建築物即將因整修而關閉。|The building will soon be closed for [renovations].|reservations;regulations;registrations
vocab|この保証は購入日から1年間有効です。|이 보증은 구입일로부터 1년간 유효합니다.|這份保固自購買日起一年內有效。|This warranty is [valid] for one year from the date of purchase.|vacant;various;visible
vocab|売上は前年に比べて大幅に増えました。|매출은 전년에 비해 크게 늘었습니다.|銷售額比去年大幅增加。|Sales increased [considerably] compared to last year.|considerately;consistently;consequently
vocab|すべての出張費は事前に承認が必要です。|모든 출장비는 사전 승인이 필요합니다.|所有出差費用都需要事先核准。|All travel expenses require [approval] in advance.|approach;appeal;appliance
vocab|その申込書に必要事項を記入してください。|그 신청서에 필요 사항을 기입해 주십시오.|請在申請表上填寫必要事項。|Please [fill out] the application form.|fill up;put off;turn out
"""
}
