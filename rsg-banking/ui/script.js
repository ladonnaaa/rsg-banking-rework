var currentBankId = null;
var isTransacting = false;

const formatMoney = (amount) => {
    let val = parseFloat(amount) || 0;
    return val.toLocaleString('en-US', { style: 'currency', currency: 'USD' });
};


function playSoundSafely(elementId, volume = 0.5) {
    let audio = document.getElementById(elementId);
    if(audio) {
        audio.volume = volume;
        audio.currentTime = 0;
        let playPromise = audio.play();
        if (playPromise !== undefined) {
            playPromise.catch(error => {
                console.log(`Zvuk ${elementId} nebyl nalezen nebo je blokován prohlížečem.`);
            });
        }
    }
}

window.addEventListener('message', (event) => {
    let data = event.data;

    if (data.action === "OPEN_BANK") {
        currentBankId = data.id;
        $('#player-name').text(data.playerName);
        updateBalances(data);
        updateLogs(data.logs);
        
        if (data.blacklisted) {
            $('#exekuce-warn').show();
        } else {
            $('#exekuce-warn').hide();
        }

        $('#ledger-container').fadeIn(400);
    }
    
    if (data.action === "CLOSE_BANK") {
        $('#ledger-container').fadeOut(400);
    }

    if (data.action === "UPDATE_DATA") {
        updateBalances(data);
        if(data.logs) {
            updateLogs(data.logs);
        }
    }

    if (data.action === "SHOW_STAMP") {
        showDynamicStamp(data.text, data.subtext, data.color);
    }
});

function updateBalances(data) {
    $('#bal-bank').text(formatMoney(data.balance));
    $('#bal-cash').text(formatMoney(data.cash));
    $('#bal-savings').text(formatMoney(data.savings));
    $('#bal-loan').text(formatMoney(data.loan));
}

function updateLogs(logs) {
    let container = $('#transaction-log');
    container.empty();

    if (!logs || logs.length === 0) return;

    logs.forEach(log => {
        let isPos = (log.type === "deposit" || log.type === "loan" || log.type === "sell_gold");
        let colorClass = isPos ? 'log-pos' : 'log-neg';
        let sign = isPos ? '+' : '-';
        
        let html = `
            <li>
                <div class="log-row">
                    <span class="log-desc">${log.description}</span>
                    <span class="${colorClass}">${sign}${formatMoney(log.amount)}</span>
                </div>
            </li>
        `;
        container.append(html);
    });
}

function showDynamicStamp(titleText, subText, colorClass) {
    playSoundSafely("snd-stamp", 0.6);

    let stamp = $('#stamp-container');
    $('#stamp-title').text(titleText);
    $('#stamp-subtext').text(subText);
    
    stamp.removeClass('color-green color-red');
    if (colorClass === 'green') stamp.addClass('color-green');
    if (colorClass === 'red') stamp.addClass('color-red');

    stamp.addClass('stamp-active');
    
    setTimeout(() => {
        stamp.removeClass('stamp-active');
    }, 4500);
}

$('.btn-grid button').click(function() {
    if (isTransacting) return;
    
    let amount = parseFloat($('#trans-amount').val());
    let type = $(this).data('type');

    if (!amount || amount <= 0) return;

    playSoundSafely("snd-coins", 0.4);

    isTransacting = true;
    $.post(`https://${GetParentResourceName()}/Transact`, JSON.stringify({
        type: type,
        amount: amount,
        id: currentBankId
    }));
    
    $('#trans-amount').val('');
    setTimeout(() => { isTransacting = false; }, 800);
});

$('#btn-safedeposit').click(() => {
    $.post(`https://${GetParentResourceName()}/SafeDeposit`);
});

$('#btn-close').click(() => {
    $.post(`https://${GetParentResourceName()}/CloseNUI`);
});

document.onkeyup = function (data) {
    if (data.which == 27) {
        $.post(`https://${GetParentResourceName()}/CloseNUI`);
    }
};
