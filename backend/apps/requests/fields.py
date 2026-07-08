"""
Custom DRF serializer fields for Registration Requests app.
"""
import re

from rest_framework import serializers


class KgPhoneField(serializers.Field):
    """
    DRF serializer field that validates Kyrgyzstan phone numbers (+996).

    Accepts:  +996XXXXXXXXX, 996XXXXXXXXX, +996 (XXX) XX-XX-XX
    Cleans to 12-digit string (e.g. "996700123456").
    """

    def to_internal_value(self, data):
        if not data or not isinstance(data, str) or not data.strip():
            raise serializers.ValidationError("Номер телефона обязателен.")

        # Strip all non-digit characters
        digits = re.sub(r"\D", "", data)

        if len(digits) < 3:
            raise serializers.ValidationError(
                "Неверный формат номера. Введите номер в формате +996 (XXX) XX-XX-XX"
            )

        # Ensure it starts with 996 (Kyrgyzstan country code)
        if not digits.startswith("996"):
            raise serializers.ValidationError(
                "Номер должен быть Кыргызстанским (+996)."
            )

        # Total digits should be exactly 12: 996 + 9 digits
        if len(digits) != 12:
            raise serializers.ValidationError(
                "Неверная длина номера. Номер Кыргызстана содержит 9 цифр после +996."
            )

        return digits

    def to_representation(self, value):
        # Format for display: +996 (XXX) XX-XX-XX
        if value and len(value) == 12:
            return f"+996 ({value[3:6]}) {value[6:8]}-{value[8:10]}-{value[10:12]}"
        return value



