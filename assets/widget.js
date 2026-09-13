(function () {
  var replies = [
    { test: /인증\s*마크|마크|배지/, answer: "인증마크는 감사관 다수결로 검사를 통과한 AI 서비스에 발급되는 온체인 인증 배지예요. '인증마크 확인' 메뉴에서 실제 발급 예시를 볼 수 있어요." },
    { test: /온체인|블록체인|체인\s*기록|해시|위\s*변조|위조|변조/, answer: "감사관의 채점 결과, 응답 해시, 판정 시각, 이의제기 대화까지 전부 해시로 만들어 블록체인에 고정해요. 한 번 기록되면 누구도 임의로 수정할 수 없고, 검증 페이지에서 트랜잭션을 직접 확인할 수 있어요." },
    { test: /AI\s*인증|서비스\s*소개|AIT(가|는|란)?\s*(뭐|무엇)|뭐\s*하는\s*(곳|서비스|회사)|어떤\s*서비스/, answer: "AIT는 고영향 AI 서비스를 독립 감사관 네트워크가 검사하고, 그 결과를 블록체인에 기록해 누구나 검증할 수 있는 인증 마크를 발급하는 서비스예요. AI기본법이 요구하는 설명·근거 보관 의무를 기술적으로 충족시켜드려요." },
    { test: /가격|비용|요금|구독/, answer: "기관 인증은 연 구독 방식이에요. 정확한 견적은 기관 규모와 검사 대상 서비스 수에 따라 달라지니, 상담 신청을 남겨주시면 안내드릴게요." },
    { test: /감사관|검사\s*방법|어떻게\s*검사/, answer: "독립된 감사관 서버 2~3대가 동시에 표준 문항으로 채점하고, 다수결로 결과를 확정한 뒤 온체인에 기록해요. 홈 화면의 '작동 방식'에서 4단계 흐름을, '서비스 소개'에서 5가지 신뢰 지표와 컨트랙트 구조를 확인할 수 있어요." },
    { test: /이의\s*제기|이의제기/, answer: "검사 결과에 동의하지 않으면 이의제기를 접수할 수 있어요. AI 스크리닝 후 제3의 감사관이 재검토하고, 모든 대화 기록은 해시로 온체인에 남아요." },
    { test: /로그인|가입|등록/, answer: "기관 등록은 로그인 후 대시보드에서 진행할 수 있어요. 오른쪽 상단의 '기관 등록하기'를 눌러보세요." },
    { test: /안녕|hi|hello/i, answer: "안녕하세요! AIT 도우미예요. 인증마크, 검사 절차, 이의제기, 온체인 기록 등 무엇이든 물어보세요." },
  ];
  var fallback = "질문 감사해요. 자세한 답변은 담당자 상담이 필요할 수 있어요 — 대시보드에서 '새 검사 신청'을 통해 문의를 남겨주세요.";

  function reply(text) {
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].test.test(text)) return replies[i].answer;
    }
    return fallback;
  }

  function randomHash() {
    var chars = "0123456789abcdef";
    var head = "", tail = "";
    for (var i = 0; i < 4; i++) head += chars[Math.floor(Math.random() * 16)];
    for (var j = 0; j < 4; j++) tail += chars[Math.floor(Math.random() * 16)];
    return "0x" + head + "…" + tail;
  }

  function el(tag, attrs, children) {
    var e = document.createElement(tag);
    if (attrs) for (var k in attrs) {
      if (k === "class") e.className = attrs[k];
      else if (k === "text") e.textContent = attrs[k];
      else e.setAttribute(k, attrs[k]);
    }
    (children || []).forEach(function (c) { e.appendChild(c); });
    return e;
  }

  function init() {
    var root = el("div", { class: "ait-widget-root" });

    var fab = el("button", { class: "ait-fab", "aria-label": "AIT 도우미 열기" }, [
      el("img", { src: "assets/svg.png", alt: "AIT 도우미" })
    ]);

    var panel = el("div", { class: "ait-panel" });
    var header = el("div", { class: "ait-panel-header" }, [
      el("img", { src: "assets/svg.png", alt: "" }),
      el("div", { class: "ait-panel-title" }, [
        el("div", { text: "AIT 도우미" }),
        el("div", { class: "ait-panel-sub" }, [
          el("span", { class: "mini-badge" }, [el("img", { src: "assets/mark.png", alt: "AIT 인증" })]),
          el("span", { text: "AIT 인증됨 · 대화 온체인 기록" })
        ])
      ]),
      el("button", { class: "ait-panel-close", "aria-label": "닫기", text: "×" })
    ]);
    var body = el("div", { class: "ait-panel-body" });
    var inputRow = el("div", { class: "ait-panel-input" });
    var input = el("input", { type: "text", placeholder: "궁금한 점을 물어보세요" });
    var sendBtn = el("button", { class: "ait-send-btn", text: "전송" });
    inputRow.appendChild(input);
    inputRow.appendChild(sendBtn);

    panel.appendChild(header);
    panel.appendChild(body);
    panel.appendChild(inputRow);

    root.appendChild(panel);
    root.appendChild(fab);
    document.body.appendChild(root);

    function addMsg(text, who) {
      var group = el("div", { class: "ait-msg-group " + who });
      var bubble = el("div", { class: "ait-msg ait-msg-" + who, text: text });
      var meta = el("div", { class: "ait-msg-meta" }, [
        el("span", { class: "dot" }),
        el("span", { text: "온체인 기록됨 · " + randomHash() })
      ]);
      group.appendChild(bubble);
      group.appendChild(meta);
      body.appendChild(group);
      body.scrollTop = body.scrollHeight;
    }

    function openPanel() {
      panel.classList.add("open");
      if (!body.children.length) {
        addMsg("안녕하세요! AIT 도우미예요. 인증마크, 검사 절차, 이의제기 등 무엇이든 물어보세요.", "bot");
      }
      input.focus();
    }
    function closePanel() { panel.classList.remove("open"); }

    fab.addEventListener("click", function () {
      panel.classList.contains("open") ? closePanel() : openPanel();
    });
    header.querySelector(".ait-panel-close").addEventListener("click", closePanel);

    function send() {
      var text = input.value.trim();
      if (!text) return;
      addMsg(text, "user");
      input.value = "";
      setTimeout(function () { addMsg(reply(text), "bot"); }, 500);
    }
    sendBtn.addEventListener("click", send);
    input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") send();
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
