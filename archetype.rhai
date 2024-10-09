let context = #{};

if switch_enabled("debug-answers") {
    display("Answers:");
    display(as_yaml(ANSWERS));
}

context += render(Archetype("org-prompts"), ANSWERS);

context += prompt("Author:", "author_full", #{
    help: "Author and Email",
});

context += set("organization-name", render("{{org-name}}-{{venture-name}}", context), #{
    cases: [
        CasedIdentityCasedValue(PROGRAMMING_CASES),
        FixedKeyCasedValue("organization-title", TitleCase),
        FixedKeyCasedValue("OrganizationTitle", TitleCase),
    ],
});

context += prompt("Features:", "features", #{
  type: MultiSelect([
    "Federated GraphQL Gateway",
    "Java Libraries",
    "Frontend", 
    "Documentation Book",
  ]),
});

context.gateways = prompt("Domain Gateways:", #{
  type: List,
  answer_key: "gateways",
  help: "GraphQL Domain Gateways",
});

context.orchestrators = prompt("Orchestrators", #{
  type: List,
  answer_key: "orchestrators",
  help: "Orchestrate Workflows across multiple Services"
});

context.services = prompt("Services:", #{
  type: List,
  answer_key: "services",
  help: "Micro Services",
});

context.adapters = prompt("Adapters:", #{
  type: List,
  answer_key: "adapters",
  help: "Adapters for external systems",
});

context.assessors = prompt("Assessors:", #{
  type: List,
  answer_key: "assessors",
  help: "Rule Engine Service",
});

if switch_enabled("debug-context") {
    display("Context:");
    display(as_yaml(context));
}

if context.features.contains("Federated GraphQL Gateway") {
  log(Info, `Rendering Federated Gateway`);
  render(Archetype("federated-gateway"), context["org-venture-name"], #{
    "org-name": context["org-name"],
    "venture-name": context["venture-name"],
  });
}

if context.features.contains("Java Libraries") {
  log(Info, `Rendering Java Libraries`);
  render(Archetype("java-libs"), context["organization-name"], #{
    "org-name": context["org-name"],
    "venture-name": context["venture-name"],
    "standard": "v2",
  });
}

if context.features.contains("Documentation Book") {
  log(Info, `Rendering Documentation Book`);
  let destination = context["organization-name"];
  let answers = #{
    "org-name": context["org-name"],
    "venture-name": context["venture-name"],
    "project-name": context["organization-name"] + " Documentation",
    "author_full": context["author_full"],
  };
  let settings = #{
    use_defaults_all: true,
  };
  render(Archetype("mdbook"), destination, answers, settings);
}

fn render_app_set(apps, archetype_name, suffix, context) {
    let archetype = Archetype(archetype_name);
    let local_context = #{
      "org-name": context["org-name"],
      "venture-name": context["venture-name"],
      "project-suffix": suffix,
      "persistence": "CockroachDb",
      "platform-version": "1.0.0-SNAPSHOT",
      "standard": "v2",
    };
    for app in apps {
      log(Info, `Rendering ${pascal_case(app)} ${suffix}`);
      archetype.render(
        context["organization-name"], 
        local_context + #{ "project-prefix": app, }
      );
    }
}


render_app_set(context.gateways, "domain-gateway", "Domain Gateway", context);
render_app_set(context.orchestrators, "orchestrator", "Orchestrator", context);
render_app_set(context.services, "service", "Service", context);
render_app_set(context.adapters, "adapter", "Adapter", context);
render_app_set(context.assessors, "assessor", "Assessor", context);

