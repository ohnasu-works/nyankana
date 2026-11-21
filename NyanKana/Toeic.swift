import Foundation

/// TOEIC Part 5 style drill (incomplete sentences, business English).
/// Unlocked by premium or by clearing graduation (`AppState.toeicUnlocked`).
/// Line format: point | ja | ko | zh | sentence with [answer] | wrong;wrong;wrong
enum ToeicBank {
    static let all: [Question] = (raw + "\n" + raw2).split(separator: "\n").compactMap { line in
        let f = line.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
        guard f.count == 6, let o = f[4].firstIndex(of: "["), let c = f[4].firstIndex(of: "]") else { return nil }
        let pre = String(f[4][..<o]).trimmingCharacters(in: .whitespaces)
        let a = String(f[4][f[4].index(after: o)..<c])
        let post = String(f[4][f[4].index(after: c)...]).trimmingCharacters(in: .whitespaces)
        var q = Question.blank(f[1], pre, a, post, [a] + f[5].split(separator: ";").map(String.init), "toeic." + f[0])
        q.ko = f[2]; q.zh = f[3]
        return q
    }

    static func session(_ n: Int = 10) -> [Question] { Array(all.shuffled().prefix(n)) }

    /// rough TOEIC (L&R) score from the Part 5 accuracy — a guide only
    static func estimate(_ right: Int, of total: Int) -> Int {
        let r = Double(right) / Double(max(1, total))
        let table: [(Double, Double)] = [(0, 150), (0.3, 300), (0.5, 450), (0.7, 650), (0.85, 800), (0.95, 900), (1, 960)]
        for k in 1..<table.count where r <= table[k].0 {
            let (x0, y0) = table[k - 1], (x1, y1) = table[k]
            let v = y0 + (y1 - y0) * (r - x0) / (x1 - x0)
            return Int((v / 5).rounded()) * 5
        }
        return 960
    }

    private static let raw = """
pos|会議は午後3時に始まる予定です。|회의는 오후 3시에 시작될 예정입니다.|會議預定下午三點開始。|The meeting is [scheduled] to begin at 3 P.M.|schedule;scheduling;schedules
pos|新しいソフトウェアは非常に効率的であることがわかりました。|새 소프트웨어는 매우 효율적인 것으로 밝혀졌습니다.|新軟體被證明非常有效率。|The new software has proven to be extremely [efficient].|efficiency;efficiently;efficiencies
pos|ご協力に心より感謝いたします。|협조해 주셔서 진심으로 감사드립니다.|衷心感謝您的協助。|We [sincerely] appreciate your cooperation.|sincere;sincerity;sincerest
pos|応募者は全員、身分証明書を提示しなければなりません。|모든 지원자는 신분증을 제시해야 합니다.|所有應徵者都必須出示身分證件。|All [applicants] must present a form of identification.|apply;applied;applicable
pos|その報告書は丁寧に準備されていました。|그 보고서는 꼼꼼하게 준비되었습니다.|那份報告準備得很仔細。|The report was [carefully] prepared by the finance team.|careful;care;carefulness
pos|顧客満足が私たちの最優先事項です。|고객 만족이 우리의 최우선 과제입니다.|顧客滿意是我們的首要任務。|Customer [satisfaction] is our top priority.|satisfy;satisfied;satisfying
pos|新しい方針は来月から有効になります。|새 방침은 다음 달부터 시행됩니다.|新政策將從下個月起生效。|The new policy will become [effective] next month.|effect;effectively;effectiveness
pos|彼女はそのプロジェクトに大きく貢献しました。|그녀는 그 프로젝트에 크게 기여했습니다.|她對那個專案貢獻很大。|She made a [significant] contribution to the project.|significance;significantly;signify
pos|売上は前四半期から着実に伸びています。|매출이 지난 분기부터 꾸준히 증가하고 있습니다.|銷售額自上一季以來穩定成長。|Sales have increased [steadily] since last quarter.|steady;steadiness;steadied
pos|その工場は環境規制を厳しく守っています。|그 공장은 환경 규제를 엄격히 준수합니다.|那家工廠嚴格遵守環保法規。|The factory [strictly] follows environmental regulations.|strict;strictness;stricter
pos|経営陣はその提案を承認しました。|경영진은 그 제안을 승인했습니다.|管理階層批准了那項提案。|The management gave its [approval] to the proposal.|approve;approved;approving
pos|このホテルは駅から簡単に行けます。|이 호텔은 역에서 쉽게 갈 수 있습니다.|從車站很容易到達這家飯店。|The hotel is [easily] accessible from the station.|easy;ease;easier
verb|小包は昨日発送されました。|소포는 어제 발송되었습니다.|包裹昨天已寄出。|The package [was shipped] yesterday.|ships;was shipping;has shipped
verb|田中さんは10年間この会社で働いています。|다나카 씨는 10년 동안 이 회사에서 일해 왔습니다.|田中先生已在這家公司工作十年了。|Mr. Tanaka [has worked] for this company for ten years.|works;is working;will work
verb|部長が到着したら会議を始めます。|부장님이 도착하면 회의를 시작하겠습니다.|經理到了之後我們就開始開會。|We will start the meeting when the manager [arrives].|will arrive;arrived;arriving
verb|全従業員が研修に参加することが求められています。|모든 직원은 연수에 참가해야 합니다.|所有員工都必須參加培訓。|All employees are required [to attend] the training.|attending;attend;attended
verb|私たちは新しい倉庫の建設を検討しています。|우리는 새 창고 건설을 검토하고 있습니다.|我們正在考慮興建新倉庫。|We are considering [building] a new warehouse.|to build;build;built
verb|その書類は明日までに提出されなければなりません。|그 서류는 내일까지 제출되어야 합니다.|那份文件必須在明天之前提交。|The documents must [be submitted] by tomorrow.|submit;submitting;have submitting
verb|来週の今ごろ、私は東京に出張しているでしょう。|다음 주 이맘때 나는 도쿄에 출장 중일 것입니다.|下週這個時候我會在東京出差。|This time next week, I [will be traveling] to Tokyo on business.|travel;have traveled;was traveling
verb|お客様がいらっしゃる前に、部屋はすでに掃除されていました。|손님이 도착하기 전에 방은 이미 청소되어 있었습니다.|客人到達之前，房間已經打掃好了。|The room [had been cleaned] before the guests arrived.|has cleaned;was cleaning;cleans
verb|カタログをお送りすることを楽しみにしております。|카탈로그를 보내 드리기를 기대하고 있습니다.|我們期待寄目錄給您。|We look forward to [sending] you our catalog.|send;sent;be sent
verb|マネージャーは私に報告書を見直させました。|매니저는 나에게 보고서를 검토하게 했습니다.|經理要我重新檢查報告。|The manager had me [review] the report.|to review;reviewed;reviewing
verb|彼は会議の準備で忙しい。|그는 회의 준비로 바쁩니다.|他正忙著準備會議。|He is busy [preparing] for the meeting.|to prepare;prepare;prepared
verb|新製品は先月発売されて以来、よく売れています。|신제품은 지난달 출시된 이후 잘 팔리고 있습니다.|新產品自上個月推出以來一直很暢銷。|The new product has sold well since it [was launched] last month.|launched;has launched;launches
prep|書類は金曜日までに提出してください。|서류는 금요일까지 제출해 주세요.|請在星期五之前提交文件。|Please submit the forms [by] Friday.|until;on;at
prep|オフィスは月曜日から金曜日まで開いています。|사무실은 월요일부터 금요일까지 엽니다.|辦公室週一到週五營業。|The office is open from Monday [through] Friday.|by;since;within
prep|悪天候にもかかわらず、イベントは予定通り行われました。|악천후에도 불구하고 행사는 예정대로 진행되었습니다.|儘管天氣惡劣，活動仍如期舉行。|[Despite] the bad weather, the event was held as planned.|Although;Even;However
prep|会議中は携帯電話の電源をお切りください。|회의 중에는 휴대전화를 꺼 주세요.|開會期間請關閉手機。|Please turn off your phones [during] the meeting.|while;since;among
prep|その店は駅の向かいにあります。|그 가게는 역 맞은편에 있습니다.|那家店在車站對面。|The store is located [across from] the station.|next;between;among
prep|返金は購入日から30日以内に申請してください。|환불은 구입일로부터 30일 이내에 신청해 주세요.|請於購買日起三十天內申請退款。|Refunds must be requested [within] 30 days of purchase.|during;until;since
prep|交通渋滞のため、電車は遅れました。|교통 체증 때문에 기차가 늦었습니다.|因為交通壅塞，列車誤點了。|The train was delayed [due to] heavy traffic.|because;so that;although
prep|新しいオフィスは駅の近くにあります。|새 사무실은 역 근처에 있습니다.|新辦公室在車站附近。|The new office is conveniently located [near] the station.|nearly;nearby of;nearness
prep|その会議はおよそ2時間続きました。|그 회의는 약 2시간 동안 계속되었습니다.|那場會議持續了大約兩小時。|The conference lasted [for] about two hours.|during;while;since
prep|スミス氏に代わって、私がご挨拶申し上げます。|스미스 씨를 대신해 제가 인사드리겠습니다.|我代表史密斯先生向各位致意。|[On behalf of] Mr. Smith, I would like to welcome you.|In case of;Instead;In spite of
conj|雨が降っていたが、多くの人がフェスティバルに来ました。|비가 왔지만 많은 사람들이 축제에 왔습니다.|雖然下著雨，還是有很多人來參加慶典。|[Although] it was raining, many people came to the festival.|Despite;However;Because of
conj|ご質問があれば、お気軽にご連絡ください。|질문이 있으시면 편하게 연락 주세요.|如有任何問題，請隨時與我們聯絡。|[If] you have any questions, please feel free to contact us.|Unless;Whether;Despite
conj|予約をしない限り、席は保証されません。|예약하지 않으면 좌석은 보장되지 않습니다.|除非預約，否則不保證有座位。|Seats are not guaranteed [unless] you make a reservation.|if;because;whether
conj|新しいプリンターは速いだけでなく、静かです。|새 프린터는 빠를 뿐만 아니라 조용합니다.|新印表機不只速度快，而且很安靜。|The new printer is not only fast [but also] quiet.|and also;or;as well
conj|田中さんか鈴木さんのどちらかが会議に出席します。|다나카 씨나 스즈키 씨 중 한 명이 회의에 참석합니다.|田中先生或鈴木先生其中一人會出席會議。|Either Ms. Tanaka [or] Mr. Suzuki will attend the meeting.|nor;and;but
conj|報告書が完成次第、お送りします。|보고서가 완성되는 대로 보내 드리겠습니다.|報告一完成，我就寄給您。|I will send you the report [as soon as] it is finished.|as long as;as well as;so that
conj|全員が理解できるように、彼はゆっくり話しました。|모두가 이해할 수 있도록 그는 천천히 말했습니다.|為了讓大家都聽得懂，他說得很慢。|He spoke slowly [so that] everyone could understand.|such as;even if;as if
conj|売上は伸びた。しかし、利益は減少した。|매출은 늘었다. 하지만 이익은 줄었다.|銷售額增加了。然而，利潤卻減少了。|Sales increased. [However], profits decreased.|Although;Despite;Unless
conj|彼女は経験が豊富なので、リーダーに選ばれました。|그녀는 경험이 풍부해서 리더로 뽑혔습니다.|因為她經驗豐富，所以被選為領導者。|She was chosen as leader [because] she has a lot of experience.|because of;despite;so
pron|参加者は各自の昼食を持参してください。|참가자는 각자 점심을 가져오세요.|參加者請自備午餐。|Participants should bring [their] own lunch.|them;they;theirs
pron|そのデザインは彼女自身が作成しました。|그 디자인은 그녀가 직접 만들었습니다.|那個設計是她親自做的。|She created the design [herself].|her;hers;she
pron|応募書類を受け取ったら、あなたに連絡します。|지원 서류를 받으면 연락드리겠습니다.|收到申請文件後，我們會與您聯絡。|We will contact [you] once we receive the application.|your;yours;yourself
pron|この仕事を担当している人は誰でも報告書を書かなければなりません。|이 업무를 담당하는 사람은 누구든지 보고서를 써야 합니다.|負責這項工作的人都必須寫報告。|[Whoever] is in charge of this task must write a report.|Whom;Whose;Which
pron|講演者の一人は、私が以前一緒に働いた人です。|강연자 중 한 명은 내가 전에 함께 일했던 사람입니다.|其中一位講者是我以前的同事。|One of the speakers is someone [whom] I worked with before.|which;whose;what
pron|私たちが開発した製品は好評です。|우리가 개발한 제품은 호평을 받고 있습니다.|我們開發的產品廣受好評。|The product [that] we developed has been well received.|what;who;whose
pron|本社がシンガポールにある会社と契約しました。|본사가 싱가포르에 있는 회사와 계약했습니다.|我們和一家總部在新加坡的公司簽了約。|We signed a contract with a company [whose] headquarters is in Singapore.|which;who;that
vocab|お支払いは同封の封筒でお送りください。|결제는 동봉된 봉투로 보내 주세요.|請用隨附的信封寄送款項。|Please send your payment in the [enclosed] envelope.|enclosing;enclose;enclosure
vocab|その職には少なくとも3年の経験が必要です。|그 직책에는 최소 3년의 경험이 필요합니다.|那個職位需要至少三年的經驗。|The position [requires] at least three years of experience.|requests;asks;needs of
vocab|ご不便をおかけして申し訳ございません。|불편을 드려 죄송합니다.|造成您的不便，我們深感抱歉。|We apologize for any [inconvenience] this may cause.|inconvenient;inconveniently;inconvenienced
vocab|そのイベントの参加費は無料です。|그 행사의 참가비는 무료입니다.|那場活動免費參加。|[Admission] to the event is free of charge.|Admit;Access to;Entrance of
vocab|予算の制約のため、計画は延期されました。|예산 제약 때문에 계획이 연기되었습니다.|由於預算限制，計畫被延後了。|The plan was [postponed] because of budget limits.|prevented;delayed of;stopped by
vocab|新しい部長は来月就任します。|새 부장은 다음 달 취임합니다.|新任經理將於下個月就任。|The new director will [assume] her position next month.|consume;resume;presume
vocab|弊社の製品は一年間の保証付きです。|당사 제품은 1년 보증이 붙어 있습니다.|本公司產品享有一年保固。|Our products come with a one-year [warranty].|guarantee to;insurance;promise
vocab|注文の状況はウェブサイトで確認できます。|주문 상황은 웹사이트에서 확인할 수 있습니다.|您可以在網站上查詢訂單狀態。|You can check the [status] of your order on our website.|state;stature;statue
vocab|会議は大成功で、多くの新規顧客を獲得しました。|회의는 대성공이었고 많은 신규 고객을 얻었습니다.|會議非常成功，我們獲得了許多新客戶。|The conference was a great success, and we [gained] many new clients.|earned of;won to;reached
vocab|この割引は会員のみに適用されます。|이 할인은 회원에게만 적용됩니다.|這個折扣只適用於會員。|This discount [applies] only to members.|applicants;appliances;applies for
vocab|プロジェクトの締め切りが一週間延長されました。|프로젝트 마감이 일주일 연장되었습니다.|專案的截止日期延長了一週。|The project deadline has been [extended] by one week.|extensive;extension;extend
vocab|従業員は安全規則に従う必要があります。|직원은 안전 규칙을 따라야 합니다.|員工必須遵守安全規定。|Employees must [comply] with the safety rules.|obey;follow;observe
pos|その会社は昨年、利益を大幅に増やしました。|그 회사는 작년에 이익을 크게 늘렸습니다.|那家公司去年大幅增加了利潤。|The company increased its profits [considerably] last year.|considerable;consider;consideration
pos|この部屋は会議に適しています。|이 방은 회의에 적합합니다.|這個房間適合開會。|This room is [suitable] for meetings.|suit;suitably;suitability
pos|新しい機械の導入で生産性が向上しました。|새 기계 도입으로 생산성이 향상되었습니다.|引進新機器後生產力提高了。|The [introduction] of new machines improved productivity.|introduce;introductory;introduced
pos|応募書類はすべて慎重に審査されます。|모든 지원 서류는 신중하게 심사됩니다.|所有申請文件都會被仔細審查。|All applications will be reviewed [thoroughly].|thorough;thoroughness;more thorough
pos|彼の説明はとてもわかりやすかった。|그의 설명은 아주 이해하기 쉬웠습니다.|他的說明非常清楚易懂。|His explanation was very [clear].|clearly;clarity;clarify
pos|その製品の需要は依然として高い。|그 제품의 수요는 여전히 높습니다.|那項產品的需求依然很高。|[Demand] for the product remains high.|Demanding;Demanded;Demandingly
pos|研修は新入社員にとって非常に有益でした。|연수는 신입 사원에게 매우 유익했습니다.|研修對新員工非常有益。|The training was highly [beneficial] to new employees.|benefit;beneficially;benefited
pos|マネージャーは決定について会議で発表しました。|매니저는 결정에 대해 회의에서 발표했습니다.|經理在會議上宣布了決定。|The manager made an [announcement] about the decision.|announce;announced;announcer
pos|その店は手頃な価格で知られています。|그 가게는 저렴한 가격으로 알려져 있습니다.|那家店以價格實惠聞名。|The store is known for its [affordable] prices.|afford;affordably;affordability
pos|彼女は会社で最も信頼できる社員の一人です。|그녀는 회사에서 가장 믿을 수 있는 직원 중 한 명입니다.|她是公司裡最可靠的員工之一。|She is one of the most [reliable] employees in the company.|rely;reliably;reliance
verb|経理部は来週オフィスを移転する予定です。|경리부는 다음 주에 사무실을 이전할 예정입니다.|會計部預計下週搬遷辦公室。|The accounting department is going to [relocate] next week.|relocated;relocating;relocates
verb|その報告書は月曜日までに完成させる必要があります。|그 보고서는 월요일까지 완성해야 합니다.|那份報告需要在星期一前完成。|The report needs [to be completed] by Monday.|be completed;to complete;completed
verb|新しいシステムが導入されてから、ミスが減りました。|새 시스템이 도입된 이후 실수가 줄었습니다.|新系統導入後，錯誤減少了。|Errors have decreased since the new system [was introduced].|introduced;has introduced;introducing
verb|もし質問があれば、私に直接連絡してください。|질문이 있으면 저에게 직접 연락해 주세요.|如果有問題，請直接聯絡我。|Should you have any questions, please [contact] me directly.|contacting;to contact;contacted
verb|その会議は悪天候のため延期されました。|그 회의는 악천후로 연기되었습니다.|那場會議因天候不佳而延期。|The meeting [was postponed] due to bad weather.|postponed;has postponed;postponing
verb|彼は5年間ずっと営業部で働いています。|그는 5년 동안 영업부에서 일해 왔습니다.|他在業務部工作已經五年了。|He [has been working] in the sales department for five years.|is working;works;was worked
verb|社長は全員に会議に出席するよう求めました。|사장은 모두에게 회의에 참석하도록 요청했습니다.|社長要求所有人出席會議。|The president asked everyone [to attend] the meeting.|attend;attending;attended
verb|部品は来週の火曜日までに届くはずです。|부품은 다음 주 화요일까지 도착할 것입니다.|零件應該會在下週二前送達。|The parts [should arrive] by next Tuesday.|should arriving;should arrived;should to arrive
verb|このソフトウェアを使えば作業時間を短縮できます。|이 소프트웨어를 사용하면 작업 시간을 단축할 수 있습니다.|使用這套軟體可以縮短作業時間。|Using this software can help [reduce] working hours.|reducing;reduced;reduction
verb|私たちが到着したとき、セミナーはすでに始まっていました。|우리가 도착했을 때 세미나는 이미 시작되었습니다.|我們到達時，研討會已經開始了。|The seminar [had already begun] when we arrived.|has already begun;already begins;was already begin
verb|お客様のご意見は製品の改善に役立ちます。|고객의 의견은 제품 개선에 도움이 됩니다.|顧客的意見有助於改善產品。|Customer feedback helps us [improve] our products.|improvement;improving;improved
verb|受付で名前を記入するよう求められました。|접수처에서 이름을 기입하도록 요청받았습니다.|在櫃台被要求填寫姓名。|Visitors are asked [to sign] in at the reception desk.|sign;signing;signed
prep|そのセールは今月末まで続きます。|그 세일은 이달 말까지 계속됩니다.|那場特賣會持續到這個月底。|The sale will continue [until] the end of this month.|by;since;within
prep|売上は前年に比べて10パーセント増加しました。|매출은 전년에 비해 10퍼센트 증가했습니다.|銷售額比前一年增加了百分之十。|Sales rose [by] 10 percent compared to last year.|at;on;for
prep|この件に関するご質問は人事部までお願いします。|이 건에 관한 질문은 인사부로 부탁드립니다.|有關此事的問題請洽人事部。|Questions [regarding] this matter should go to the personnel department.|regard;regarded;regards
prep|会議室は2階のエレベーターの隣にあります。|회의실은 2층 엘리베이터 옆에 있습니다.|會議室在二樓電梯旁邊。|The meeting room is located [next to] the elevator on the second floor.|next;near to;beside of
prep|当店では、現金のほかにクレジットカードもご利用いただけます。|저희 가게에서는 현금 외에 신용카드도 이용할 수 있습니다.|本店除了現金也可以使用信用卡。|[In addition to] cash, we accept credit cards.|In spite of;Instead of;Because of
prep|予算の制約により、プロジェクトは縮小されました。|예산 제약으로 프로젝트가 축소되었습니다.|由於預算限制，專案被縮小了。|The project was reduced [because of] budget limits.|because;although;so that
prep|書類は封筒に入れて、受付に提出してください。|서류는 봉투에 넣어 접수처에 제출해 주세요.|請將文件放入信封交到櫃台。|Please put the documents [in] an envelope and submit them at the front desk.|on;at;over
prep|新製品の発売は来月に予定されています。|신제품 출시는 다음 달로 예정되어 있습니다.|新產品預定下個月上市。|The launch of the new product is scheduled [for] next month.|at;in;on
prep|すべての従業員は勤務中、IDカードを着用しなければなりません。|모든 직원은 근무 중 ID 카드를 착용해야 합니다.|所有員工上班時必須配戴識別證。|All staff must wear ID cards [while] on duty.|during;for;since
conj|彼は遅れて到着したが、会議に間に合った。|그는 늦게 도착했지만 회의에 늦지 않았다.|他雖然晚到了，但還是趕上了會議。|[Even though] he arrived late, he made it to the meeting.|Despite;Because of;Unless
conj|天気が良ければ、昼食会は屋外で行われます。|날씨가 좋으면 점심 모임은 야외에서 열립니다.|如果天氣好，午餐會會在戶外舉行。|The luncheon will be held outdoors [provided that] the weather is good.|in case of;despite;whether
conj|価格が高いか安いかに関わらず、品質が最も重要です。|가격이 비싸든 싸든 품질이 가장 중요합니다.|無論價格高低，品質最重要。|[Whether] the price is high or low, quality matters most.|If;Either;Neither
conj|新しいオフィスは広いだけでなく、駅にも近い。|새 사무실은 넓을 뿐만 아니라 역에서도 가깝다.|新辦公室不但寬敞，而且離車站很近。|The new office is [both] spacious and close to the station.|either;neither;whether
conj|彼女も私もその会議には出席できません。|그녀도 나도 그 회의에 참석할 수 없습니다.|她和我都不能出席那場會議。|[Neither] she nor I can attend the meeting.|Either;Both;Not only
conj|書類を確認したらすぐに、あなたに連絡します。|서류를 확인하면 바로 연락드리겠습니다.|確認文件後我會馬上聯絡你。|I will contact you [once] I have checked the documents.|whereas;unless;although
conj|在庫が限られているので、お早めにご注文ください。|재고가 한정되어 있으니 서둘러 주문해 주세요.|由於庫存有限，請盡早訂購。|Please order early, [as] stock is limited.|so;but;yet
conj|彼は経験が少ないが、とても熱心だ。|그는 경험은 적지만 매우 열정적이다.|他經驗雖少，但非常熱心。|He has little experience, [but] he is very enthusiastic.|so;because;or
pron|応募者は自分の履歴書を持参してください。|지원자는 자신의 이력서를 지참해 주세요.|應徵者請自行攜帶履歷。|Applicants should bring [their] résumés.|they;them;theirs
pron|そのプロジェクトはチーム自身で計画されました。|그 프로젝트는 팀이 직접 계획했습니다.|那個專案是團隊自己規劃的。|The team planned the project [themselves].|them;their;they
pron|これは私のファイルではありません。あなたのものですか。|이것은 내 파일이 아닙니다. 당신 것입니까?|這不是我的檔案。是你的嗎？|This file is not mine. Is it [yours]?|your;you;yourself
pron|会議に出席する人は誰でも資料を受け取れます。|회의에 참석하는 사람은 누구나 자료를 받을 수 있습니다.|出席會議的人都能拿到資料。|[Anyone] attending the meeting can receive the materials.|Anything;Any;Ones
pron|2つの案のうち、どちらも予算内には収まりませんでした。|두 안 중 어느 것도 예산 내에 들지 않았습니다.|兩個方案都超出了預算。|[Neither] of the two plans was within the budget.|Either;Both;Nor
pron|マネージャーが私たちに話した計画は良いものでした。|매니저가 우리에게 말한 계획은 좋은 것이었습니다.|經理告訴我們的計畫很好。|The plan [that] the manager told us about was good.|what;who;whose
pron|ここが私たちが新製品を発表したホールです。|여기가 우리가 신제품을 발표한 홀입니다.|這裡是我們發表新產品的大廳。|This is the hall [where] we launched the new product.|which;what;who
vocab|ご注文の品は本日発送されました。|주문하신 상품은 오늘 발송되었습니다.|您訂購的商品今天已出貨。|Your order was [shipped] today.|shopped;shaped;shared
vocab|年次総会は本社で開催されます。|연차 총회는 본사에서 개최됩니다.|年度大會將在總公司舉行。|The annual meeting will be [held] at the headquarters.|had;hold to;holding
vocab|割引クーポンは購入時にご提示ください。|할인 쿠폰은 구매 시 제시해 주세요.|折價券請在購買時出示。|Please [present] your discount coupon at the time of purchase.|presence;presently;presentation
vocab|応募の締め切りは5月31日です。|지원 마감은 5월 31일입니다.|申請截止日期是5月31日。|The [deadline] for applications is May 31.|headline;timeline;guideline
vocab|当社は顧客満足を最優先にしています。|당사는 고객 만족을 최우선으로 하고 있습니다.|本公司以顧客滿意為第一優先。|Our company gives top [priority] to customer satisfaction.|prior;priorly;prioritize
vocab|その提案は役員会で承認されました。|그 제안은 이사회에서 승인되었습니다.|那項提案在董事會上獲得批准。|The proposal was [approved] by the board.|proved;improved;reproved
vocab|経費の精算には領収書が必要です。|경비 정산에는 영수증이 필요합니다.|報銷費用需要收據。|A [receipt] is required to be reimbursed for expenses.|recipe;receiver;recipient
vocab|会議の議事録をメールで送ります。|회의록을 이메일로 보내겠습니다.|我會用電子郵件寄送會議紀錄。|I will email you the [minutes] of the meeting.|seconds;moments;hours
vocab|その工場は月に1万台の車を生産しています。|그 공장은 한 달에 1만 대의 차를 생산합니다.|那家工廠每月生產一萬輛車。|The factory [produces] 10,000 cars a month.|products;production;productive
vocab|ホテルは空港への無料送迎を提供しています。|호텔은 공항까지 무료 셔틀을 제공합니다.|飯店提供往返機場的免費接送。|The hotel offers a [complimentary] shuttle to the airport.|complementary;complimented;compliment
vocab|この契約は3年後に満了します。|이 계약은 3년 후에 만료됩니다.|這份合約三年後到期。|This contract will [expire] in three years.|expand;expect;explore
vocab|彼女は来月、部長に昇進します。|그녀는 다음 달 부장으로 승진합니다.|她下個月將升任經理。|She will be [promoted] to manager next month.|prompted;provided;protected
vocab|商品は在庫切れです。|상품은 재고가 없습니다.|商品目前缺貨。|The item is currently out of [stock].|store;stack;stick
vocab|イベントの会場は駅の近くです。|행사장은 역 근처입니다.|活動場地在車站附近。|The [venue] for the event is near the station.|value;venture;avenue
vocab|全従業員は年に一度、健康診断を受けなければなりません。|모든 직원은 1년에 한 번 건강 검진을 받아야 합니다.|所有員工每年必須接受一次健康檢查。|All employees must [undergo] a health check once a year.|underline;understand;undertaking
vocab|彼の提案は会議で多くの支持を得ました。|그의 제안은 회의에서 많은 지지를 얻었습니다.|他的提案在會議上獲得許多支持。|His proposal [gained] a lot of support at the meeting.|lost;earned up;reached to
vocab|当社のウェブサイトから製品カタログをダウンロードできます。|당사 웹사이트에서 제품 카탈로그를 다운로드할 수 있습니다.|可以從本公司網站下載產品目錄。|You can [download] our product catalog from our website.|upload;unload;overload
"""
}
