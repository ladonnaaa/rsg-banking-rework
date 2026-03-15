
# 🏦 RSG Banking Rework (Ladonna Edition)
Advanced and realistic banking system for RedM using the RSG Core framework. This resource completely reworks the default banking UI into an immersive, interactive ledger book and introduces a hardcore loan & debt collection system.

## 🌍 Language
Currently, this resource is available only in **English (EN)**. You can easily translate the UI and notifications by modifying the files inside the `locales/` folder.

## ✨ Features
* **📖 Immersive UI:** Beautiful custom UI designed as a realistic leather-bound ledger with lined paper.
* **💾 SQL-Driven Logging:** Every transaction is strictly saved to the database. No more lost transaction history after a server restart!
* **📜 Advanced Loan System:** 
  * Configure max active loans and max debt limits.
  * Time-based loans with due dates.
* **⚖️ Debt Collection:** If a player fails to pay their loan on time, the system applies interest penalties and completely blocks them from withdrawing cash or taking new loans until the debt is paid.
* **🛑 Anti-Spam Protection:** Built-in cooldowns prevent players from spamming the UI and exploiting the database.
* **💥 Dynamic Stamp Feedback:** Action results (APPROVED / DENIED) are visibly stamped onto the UI page with custom sound effects and detailed error messages.
* **🪙 Gold & Moneyclips:** Sell gold directly to the bank, and create usable physical bank checks (`money_clip` & `blood_money_clip`).
* **📡 Discord Webhooks:** Highly detailed Discord logs for every transaction type.

## 📦 Dependencies
Ensure you have the following installed on your server:
* [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
* [oxmysql](https://github.com/overextended/oxmysql)
*[ox_lib](https://github.com/overextended/ox_lib)
* [ox_target](https://github.com/overextended/ox_target)
* [rsg-inventory](https://github.com/Rexshack-RedM/rsg-inventory)

## 🛠️ Installation

**1. Download the resource**
Download the ZIP or clone the repository into your `resources` folder.
Make sure the folder name is `rsg-banking`.

**2. Run the SQL file**
Run the following SQL code in your database (HeidiSQL, phpMyAdmin, etc.) to create the necessary tables:
```sql
CREATE TABLE IF NOT EXISTS `bank_loans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `due_date` datetime NOT NULL,
  `status` varchar(20) DEFAULT 'active',
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `bank_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
);
```

**3. Add Items to RSG Core**
Make sure these items exist in your `rsg-core/shared/items.lua` or your database:
```lua
['money_clip'] = {['name'] = 'money_clip', ['label'] = 'Bank Check', ['weight'] = 0, ['type'] = 'item', ['image'] = 'money_clip.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil,['description'] = 'A usable clip of money.'},
['blood_money_clip'] = {['name'] = 'blood_money_clip', ['label'] = 'Blood Money Check', ['weight'] = 0,['type'] = 'item', ['image'] = 'blood_money_clip.png', ['unique'] = false, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil,['description'] = 'A usable clip of blood money.'},
['gold_bar'] = {['name'] = 'gold_bar', ['label'] = 'Gold Bar', ['weight'] = 1.0, ['type'] = 'item', ['image'] = 'gold_bar.png', ['unique'] = false, ['useable'] = false, ['shouldClose'] = false, ['combinable'] = nil, ['description'] = 'A heavy bar of solid gold.'},
```

**4. Start the script**
Add the following to your `server.cfg`:
```cfg
ensure rsg-banking
```

## ⚙️ Configuration
All major settings like loan limits, penalties, withdrawal fees, and Discord webhooks can be easily modified in `config.lua`.

## ⚠️ Support & Disclaimer
This resource is provided **"as-is"** completely for free. 
**I DO NOT offer any support, troubleshooting, or help with installation.** If you encounter errors, please make sure you have installed all dependencies correctly and read this README. Feel free to fork the repository and make your own changes!

## 📸 Preview
https://r2.fivemanage.com/Aea0VpArCwo9C2f1I5Lnd/image.png

## 👨‍💻 Author
Reworked and improved by **Ladonna**.
