import telebot
from telebot import types
import time

# Bot configuration
BOT_TOKEN = "7253489362:AAED1JWz195gwPLp6aKk6_zGOxOknwRMNbM"
PREMIUM_PRICE = 5  # 500 Stars for premium access

# User data storage (in a real bot, use a database)
user_data = {}

bot = telebot.TeleBot(BOT_TOKEN)


# Language selection handler
@bot.message_handler(commands=['start'])
def send_welcome(message):
    # Create language selection keyboard
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn_uz = types.KeyboardButton("🇺🇿 O'zbekcha")
    btn_ru = types.KeyboardButton("🇷🇺 Русский")
    btn_en = types.KeyboardButton("🇬🇧 English")
    markup.add(btn_uz, btn_ru, btn_en)

    bot.reply_to(message, "Iltimos, tilni tanlang / Пожалуйста, выберите язык / Please select language:",
                 reply_markup=markup)


# Language selection
@bot.message_handler(func=lambda message: message.text in ["🇺🇿 O'zbekcha", "🇷🇺 Русский", "🇬🇧 English"])
def set_language(message):
    lang = message.text
    chat_id = message.chat.id

    # Store user language preference
    if chat_id not in user_data:
        user_data[chat_id] = {}
    user_data[chat_id]['language'] = lang

    # Prepare messages based on language
    if lang == "🇺🇿 O'zbekcha":
        welcome_msg = "Xush kelibsiz! Quyidagi menyudan tanlang:"
        btn1_text = "💳 Premium obuna"
        btn2_text = "🎥 Videolar"
    elif lang == "🇷🇺 Русский":
        welcome_msg = "Добро пожаловать! Выберите из меню:"
        btn1_text = "💳 Премиум подписка"
        btn2_text = "🎥 Видео"
    else:  # English
        welcome_msg = "Welcome! Please choose from the menu:"
        btn1_text = "💳 Premium subscription"
        btn2_text = "🎥 Videos"

    # Create main menu
    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn1 = types.KeyboardButton(btn1_text)
    btn2 = types.KeyboardButton(btn2_text)
    markup.add(btn1, btn2)

    bot.send_message(chat_id, welcome_msg, reply_markup=markup)


# Video categories menu
@bot.message_handler(func=lambda message: message.text in ["🎥 Videolar", "🎥 Видео", "🎥 Videos"])
def show_video_categories(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    if lang == "🇺🇿 O'zbekcha":
        text = "Video kategoriyalar:"
        btn1_text = "📹 Oddiy video"
        btn2_text = "🔞 18+ video"
        btn3_text = "💎 Pro video"
        btn4_text = "🇺🇿 O'zbek video"
        back_text = "⬅️ Orqaga"
    elif lang == "🇷🇺 Русский":
        text = "Категории видео:"
        btn1_text = "📹 Обычное видео"
        btn2_text = "🔞 18+ видео"
        btn3_text = "💎 Pro видео"
        btn4_text = "🇺🇿 Узбекское видео"
        back_text = "⬅️ Назад"
    else:  # English
        text = "Video categories:"
        btn1_text = "📹 Regular video"
        btn2_text = "🔞 18+ video"
        btn3_text = "💎 Pro video"
        btn4_text = "🇺🇿 Uzbek video"
        back_text = "⬅️ Back"

    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn1 = types.KeyboardButton(btn1_text)
    btn2 = types.KeyboardButton(btn2_text)
    btn3 = types.KeyboardButton(btn3_text)
    btn4 = types.KeyboardButton(btn4_text)
    back_btn = types.KeyboardButton(back_text)
    markup.add(btn1, btn2, btn3, btn4, back_btn)

    bot.send_message(chat_id, text, reply_markup=markup)


# Back button handler
@bot.message_handler(func=lambda message: message.text in ["⬅️ Orqaga", "⬅️ Назад", "⬅️ Back"])
def back_to_main(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    if lang == "🇺🇿 O'zbekcha":
        welcome_msg = "Asosiy menyu:"
        btn1_text = "💳 Premium obuna"
        btn2_text = "🎥 Videolar"
    elif lang == "🇷🇺 Русский":
        welcome_msg = "Главное меню:"
        btn1_text = "💳 Премиум подписка"
        btn2_text = "🎥 Видео"
    else:  # English
        welcome_msg = "Main menu:"
        btn1_text = "💳 Premium subscription"
        btn2_text = "🎥 Videos"

    markup = types.ReplyKeyboardMarkup(resize_keyboard=True)
    btn1 = types.KeyboardButton(btn1_text)
    btn2 = types.KeyboardButton(btn2_text)
    markup.add(btn1, btn2)

    bot.send_message(chat_id, welcome_msg, reply_markup=markup)


# Regular video handler - opens free mini app
@bot.message_handler(func=lambda message: message.text in ["📹 Oddiy video", "📹 Обычное видео", "📹 Regular video"])
def show_regular_video(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    if lang == "🇺🇿 O'zbekcha":
        text = "Oddiy videolar yuklanmoqda..."
    elif lang == "🇷🇺 Русский":
        text = "Загружаю обычные видео..."
    else:  # English
        text = "Loading regular videos..."

    bot.send_message(chat_id, text)

    # Create inline button with mini app
    markup = types.InlineKeyboardMarkup()
    btn = types.InlineKeyboardButton(
        text="📹 Videolarni ko'rish" if lang == "🇺🇿 O'zbekcha" else "📹 Смотреть видео" if lang == "🇷🇺 Русский" else "📹 Watch videos",
        web_app=types.WebAppInfo(url="https://tyler-brown.com/video/kinolar")
    )
    markup.add(btn)

    bot.send_message(chat_id, "👉", reply_markup=markup)


# Premium video handlers (18+, Pro, Uzbek)
@bot.message_handler(func=lambda message: message.text in ["🔞 18+ video", "🔞 18+ видео", "🔞 18+ video",
                                                           "💎 Pro video", "💎 Pro видео", "💎 Pro video",
                                                           "🇺🇿 O'zbek video", "🇺🇿 Узбекское видео", "🇺🇿 Uzbek video"])
def handle_premium_content(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    # Check if user has premium access
    if user_data.get(chat_id, {}).get('premium_expiry', 0) > time.time():
        # User has active premium access
        if lang == "🇺🇿 O'zbekcha":
            text = "Premium kontent ochilmoqda..."
        elif lang == "🇷🇺 Русский":
            text = "Открываю премиум контент..."
        else:  # English
            text = "Opening premium content..."

        bot.send_message(chat_id, text)

        # Determine which premium content was requested
        if message.text in ["🔞 18+ video", "🔞 18+ видео", "🔞 18+ video"]:
            content_url = "https://sexy.huyamba.info/search/porno-kino/"
        elif message.text in ["💎 Pro video", "💎 Pro видео", "💎 Pro video"]:
            content_url = "https://mobi.24videos.cc/search/?text=Porno%20kinolar"
        else:
            content_url = "https://z.uz-video.top/videos/uz-porn/"

        # Create inline button with mini app for premium content
        markup = types.InlineKeyboardMarkup()
        btn_text = "🔞 Ko'rish" if "18+" in message.text else "💎 Ko'rish" if "Pro" in message.text else "🇺🇿 Ko'rish"
        if lang != "🇺🇿 O'zbekcha":
            btn_text = "🔞 Смотреть" if "18+" in message.text else "💎 Смотреть" if "Pro" in message.text else "🇺🇿 Смотреть"
            if lang == "🇬🇧 English":
                btn_text = "🔞 View" if "18+" in message.text else "💎 View" if "Pro" in message.text else "🇺🇿 View"

        btn = types.InlineKeyboardButton(
            text=btn_text,
            web_app=types.WebAppInfo(url=content_url)
        )
        markup.add(btn)

        bot.send_message(chat_id, "👉", reply_markup=markup)
    else:
        # User doesn't have premium access
        if lang == "🇺🇿 O'zbekcha":
            text = (f"Premium kontentga kirish uchun {PREMIUM_PRICE} Telegram Stars to'lov qilishingiz kerak. "
                    "Bu to'lov sizga 1 oy muddatga barcha premium kontentga kirish imkonini beradi.")
            btn_text = "💳 Premiumga obuna bo'lish"
        elif lang == "🇷🇺 Русский":
            text = (f"Для доступа к премиум контенту необходимо оплатить {PREMIUM_PRICE} Telegram Stars. "
                    "Эта оплата дает вам доступ ко всему премиум контенту на 1 месяц.")
            btn_text = "💳 Подписаться на премиум"
        else:  # English
            text = (f"To access premium content, you need to pay {PREMIUM_PRICE} Telegram Stars. "
                    "This payment gives you access to all premium content for 1 month.")
            btn_text = "💳 Subscribe to premium"

        markup = types.InlineKeyboardMarkup()
        pay_btn = types.InlineKeyboardButton(btn_text, callback_data="pay_premium")
        markup.add(pay_btn)

        bot.send_message(chat_id, text, reply_markup=markup)


# Premium subscription handler
@bot.message_handler(
    func=lambda message: message.text in ["💳 Premium obuna", "💳 Премиум подписка", "💳 Premium subscription"])
def offer_premium_subscription(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    if lang == "🇺🇿 O'zbekcha":
        text = (f"Premium obuna - {PREMIUM_PRICE} Telegram Stars\n\n"
                "Obuna haqqi 1 oy muddatga amal qiladi va quyidagi imkoniyatlarni beradi:\n"
                "- Barcha premium videolar (18+, Pro, O'zbek)\n"
                "- Cheksiz kirish imkoniyati\n"
                "- Qo'shimcha funksiyalar")
        btn_text = "💳 Obuna bo'lish"
    elif lang == "🇷🇺 Русский":
        text = (f"Премиум подписка - {PREMIUM_PRICE} Telegram Stars\n\n"
                "Подписка действует 1 месяц и дает следующие возможности:\n"
                "- Все премиум видео (18+, Pro, Узбекские)\n"
                "- Неограниченный доступ\n"
                "- Дополнительные функции")
        btn_text = "💳 Подписаться"
    else:  # English
        text = (f"Premium subscription - {PREMIUM_PRICE} Telegram Stars\n\n"
                "The subscription is valid for 1 month and provides:\n"
                "- All premium videos (18+, Pro, Uzbek)\n"
                "- Unlimited access\n"
                "- Additional features")
        btn_text = "💳 Subscribe"

    markup = types.InlineKeyboardMarkup()
    pay_btn = types.InlineKeyboardButton(btn_text, callback_data="pay_premium")
    markup.add(pay_btn)

    bot.send_message(chat_id, text, reply_markup=markup)


# Callback handler for premium payment button
@bot.callback_query_handler(func=lambda call: call.data == "pay_premium")
def handle_premium_payment(call):
    chat_id = call.message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    if lang == "🇺🇿 O'zbekcha":
        title = "Premium obuna"
        description = "1 oylik premium obuna uchun to'lov"
    elif lang == "🇷🇺 Русский":
        title = "Премиум подписка"
        description = "Оплата за 1 месяц премиум подписки"
    else:  # English
        title = "Premium subscription"
        description = "Payment for 1 month premium subscription"

    try:
        bot.send_invoice(
            chat_id=chat_id,
            title=title,
            description=description,
            invoice_payload="premium_subscription",
            provider_token="",  # Should be your payment provider token
            currency="XTR",
            prices=[types.LabeledPrice("Premium Access", PREMIUM_PRICE * 100)]  # Convert to cents
        )
    except Exception as e:
        bot.send_message(chat_id, f"Error: {str(e)}")


@bot.pre_checkout_query_handler(func=lambda query: True)
def checkout(pre_checkout_query):
    bot.answer_pre_checkout_query(pre_checkout_query.id, ok=True)


@bot.message_handler(content_types=['successful_payment'])
def got_payment(message):
    chat_id = message.chat.id
    lang = user_data.get(chat_id, {}).get('language', "🇺🇿 O'zbekcha")

    # Grant premium access for 1 month (30 days)
    user_data[chat_id]['premium_expiry'] = time.time() + (30 * 24 * 60 * 60)

    if lang == "🇺🇿 O'zbekcha":
        text = ("Premium obuna muvaffaqiyatli sotib olindi! Endi barcha premium kontentga kirishingiz mumkin.\n\n"
                "Obuna muddati: 1 oy")
    elif lang == "🇷🇺 Русский":
        text = ("Премиум подписка успешно приобретена! Теперь у вас есть доступ ко всему премиум контенту.\n\n"
                "Срок подписки: 1 месяц")
    else:  # English
        text = ("Premium subscription purchased successfully! You now have access to all premium content.\n\n"
                "Subscription period: 1 month")

    bot.reply_to(message, text)


# Start the bot
bot.polling()
