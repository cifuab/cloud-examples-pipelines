## Terraform Agent Skill with HashiCorp MCP

Terraform modules usually start with good intentions. A team wants consistency, there is some repeated Terraform, and a shared module feels like the obvious next step. Sometimes that instinct is right. Quite often, though, the real problems begin before anyone writes the module itself. The worst module pain rarely comes from bad HCL. 

It usually comes from design choices made too early or too loosely: abstracting before the pattern is stable, giving the module a vague responsibility, exposing too much of the provider surface, or quietly bundling platform concerns and workload concerns together because it was easier than drawing a firmer boundary.

That part is easy to miss because the early signs do not always look like failure. The module still validates, still deploys, and still looks neat enough in a pull request, but it is already becoming awkward in the ways that matter later. It is harder to explain, harder to review, and harder to change safely. Consumers are never completely sure what it owns and what they are supposed to supply. Optional inputs start shaping behaviour more heavily than they should, and over time the abstraction grows simply because adding another variable feels easier than admitting the original boundary was never especially good.

That was the real reason I built my terraform-module-creator agent skill. I did not want a skill that just turned a prompt into a few Terraform files and called that job done. I wanted something that helps with the design judgement that should happen before generation begins, because that is usually where the difference is made between a module that becomes genuinely useful and one that ends up as another shared layer people work around.

[Blog post here](https://thomasthornton.cloud/terraform-module-design-is-the-hard-part-so-i-built-an-agent-skill-for-it/)
