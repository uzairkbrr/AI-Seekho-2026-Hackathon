import os
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

class LLM:
    def __init__(self, model="gemini-2.5-pro"):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not set")
        self.client = genai.Client(
            api_key=api_key,
            http_options={"timeout": 120000}
        )
        self.model = model

    def generate(self, prompt, schema, temp=0.1):
        response = self.client.models.generate_content(
            model=self.model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=schema,
                temperature=temp,
            ),
        )
        return response.text
