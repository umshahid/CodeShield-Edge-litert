enum Samples {
    static let scamMessage = """
    Grandma I was arrested after an accident. Do not tell mom.
    Please buy two Apple gift cards today and send a picture of the back with the PIN.
    """

    static let scammerLines = [
        "Grandma, I was arrested after an accident.",
        "Please do not tell mom. I need this handled today.",
        "Buy two Apple gift cards and send me a picture of the back with the PIN.",
    ]

    static let benignMessage = """
    Can you pick up a Target gift card for the raffle basket? No need to send codes, just bring it tomorrow.
    """

    static let cardText = """
    Apple Gift Card
    PIN: X4KJ-P92Q-7LMA-882Z
    Keep your receipt
    """

    static let callTranscript = """
    This is the sheriff's office. Your grandson was arrested after an accident.
    Do not tell anyone and stay on the phone.
    Go buy two Apple gift cards right now and read me the PIN numbers from the back.
    """

    static let callLines = [
        "This is the sheriff's office. Your grandson was arrested after an accident.",
        "Do not tell anyone and stay on the phone.",
        "Go buy two Apple gift cards right now and read me the PIN numbers from the back.",
    ]
}
