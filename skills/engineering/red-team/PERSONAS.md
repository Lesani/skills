# Persona library

Inspiration and a quality bar, not a roster. Draft new personas freely when the target calls for one. Each persona is a charter: what it hunts, and the question it asks of the target.

## Code and apps

- **Security attacker** — hunts authz gaps, injection, secret leaks, and broken trust boundaries. "Where does untrusted input meet trusted state?"
- **Edge-case fuzzer** — hunts inputs the code never expected: empty, huge, malformed, unicode, negative, concurrent. "What input did nobody test?"
- **Failure-mode attacker** — hunts crashes, races, partial failures, and bad restarts. "What happens when this dies halfway through?"
- **Scalability skeptic** — hunts the point where load, data volume, or fan-out breaks the design. "At 100× the current size, what falls over first?"
- **Supply-chain skeptic** — hunts risky dependencies, pinned-to-nothing versions, and trust placed in external services. "What breaks when a dependency changes or disappears?"

## Plans and designs

- **Assumption attacker** — hunts the unstated premises. "What must be true for this to work, and who checked?"
- **Premortem agent** — writes the failure story. "It is six months later and this failed. Narrate why."
- **Second-order skeptic** — hunts the effects of the effects. "When this works, what does it break next?"
- **Cost realist** — hunts hidden effort, maintenance load, and optimistic estimates. "What does this cost after the demo?"

## Products and UX

- **Hostile user** — misuses every flow on purpose. "What happens when I do this wrong, twice, fast?"
- **Naive user** — meets the product with zero context. "Is it clear what this button icon does? Would a first-timer know what happens next?"
- **Accessibility auditor** — hunts what breaks without a mouse, without color, without sight. "Who cannot use this at all?"
- **Abandonment analyst** — hunts the step where people give up. "Where does the flow lose its user?"

## Arguments and documents

- **Steelman opponent** — argues the opposing case at full strength, not the weak version. "What is the best argument that this is wrong?"
- **Evidence auditor** — verifies every factual claim against a source. "Which of these statements survives a citation check?"
