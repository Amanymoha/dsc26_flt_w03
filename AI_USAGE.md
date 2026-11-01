# AI usage: dsc26-flt-w03

AI tools are allowed in this task. Fill in every section in your own words. This file is read by your Track Mentor, not by the grader.

## 1. Tools I used

- Claude 4.5 (via Claude Agent SDK)

## 2. The prompts that helped most

- "Explain the task requirements line by line and help me implement the data layer step by step."
- "Review the API status mapping requirements, specifically the 429 Retry-After logic."
- "Help me implement the UI lifecycle guards (disposed/mounted check) after asynchronous calls."

## 3. Where the assistant's code would have failed a hidden-test area, and how I noticed

During the implementation, I had to be careful about a few points where a standard AI response might fail the hidden tests:
- UTF-8 Byte Decoding: A typical AI might suggest using `response.body`, but I ensured we used `utf8.decode(response.bodyBytes)` because the task explicitly stated the server might send incorrect charset headers for Arabic text.
- Retry Policy for 429: Standard retry logic might use exponential backoff for everything. I ensured that for `RateLimited` errors, we strictly follow the `retry-after` header value (capped at 30s) as per the requirements.
- UI Lifecycle: It's easy to forget checking if the widget is still in the tree after an `await`. I implemented an `_isDisposed` flag in the ViewModel to prevent calling `notifyListeners()` after the screen is closed, which avoids "used after being disposed" errors.
- Permanent vs Transient Failures: I ensured that failures like `Unauthorized` or `NotFound` are returned immediately without any retry attempts.

## 4. My state-management choice


I chose ChangeNotifier with a ViewModel pattern.
Why: It is lightweight, built into Flutter, and perfect for managing the transition between the four states (Loading, Loaded, Empty, and Error). It also made it very easy to implement the `_isDisposed` guard to handle the "leaving mid-request" scenario safely.

