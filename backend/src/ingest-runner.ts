import { runIngest } from "./ingest.js";

async function main() {
  const result = await runIngest();
  const summary = {
    generatedAt: result.generatedAt,
    updatedSources: result.updatedSources,
    skippedSources: result.skippedSources,
    errors: result.errors,
    eventCount: result.cache.events.length
  };

  console.log(JSON.stringify(summary, null, 2));

  if (result.updatedSources.length === 0 && result.errors.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
