import re

with open('test_exams/percentage_test.md', 'r') as f:
    text = f.read()

questions = []
q_blocks = re.split(r'\*\*Q\.(\d+)\*\*', text)[1:]

for i in range(0, len(q_blocks), 2):
    q_num = int(q_blocks[i])
    q_content = q_blocks[i+1]
    
    # Split by (a), (b), (c), (d) ignoring asterisks
    parts = re.split(r'\**\([a-d]\)\**', q_content, flags=re.IGNORECASE)
    
    q_text = parts[0].replace('|', '').replace('-', '').replace('+', '').strip()
    
    opt_a = parts[1].replace('|', '').replace('-', '').replace('+', '').replace('**', '').strip() if len(parts) > 1 else 'Option A'
    opt_b = parts[2].replace('|', '').replace('-', '').replace('+', '').replace('**', '').strip() if len(parts) > 2 else 'Option B'
    opt_c = parts[3].replace('|', '').replace('-', '').replace('+', '').replace('**', '').strip() if len(parts) > 3 else 'Option C'
    opt_d = parts[4].split('|')[0].replace('-', '').replace('+', '').replace('**', '').strip() if len(parts) > 4 else 'Option D'
    
    # Determine difficulty
    if 1 <= q_num <= 5:
        diff = 'easy'
        pts = 1
    elif 6 <= q_num <= 15:
        diff = 'medium'
        pts = 2
    else:
        diff = 'hard'
        pts = 3
        
    questions.append({
        'num': q_num,
        'text': q_text,
        'options': [opt_a, opt_b, opt_c, opt_d],
        'diff': diff,
        'pts': pts
    })

ans_key_part = text.split('**ANSWER KEY**')[1]
ans_dict = {}
lines = ans_key_part.split('\n')
for i, line in enumerate(lines):
    if 'Q.' in line and '|' in line:
        q_nums = re.findall(r'Q\.(\d+)', line)
        if len(q_nums) > 0 and i+2 < len(lines):
            ans_line = lines[i+2]
            ans_vals = re.findall(r'\*\*\(([a-d])\)\*\*', ans_line)
            for j, num in enumerate(q_nums):
                if j < len(ans_vals):
                    ans_dict[int(num)] = ans_vals[j]

out = """---
title: "Percentage - Topic Test 265001"
subject: "Mathematics"
group: "SSC, Banking, State PSC"
difficulty: "medium"
duration_minutes: 45
xp_reward: 200
status: "published"
---

"""
for q in questions:
    q_num = q['num']
    out += f"## Q{q_num}\n"
    out += f"{q['text']}\n\n"
    
    correct_letter = ans_dict.get(q_num, 'a')
    letter_idx = ord(correct_letter) - ord('a')
    
    for idx, opt in enumerate(q['options']):
        mark = 'x' if idx == letter_idx else ' '
        out += f"- [{mark}] {opt}\n"
        
    out += f"\n**Points:** {q['pts']}\n"
    out += f"**Difficulty:** {q['diff']}\n"
    out += f"**Explanation:** Correct answer is ({correct_letter}).\n\n"

with open('test_exams/percentage_test_formatted.md', 'w') as f:
    f.write(out)
    
print("Formatted md created.")
