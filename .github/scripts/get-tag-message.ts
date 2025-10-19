#!/usr/bin/env node

import { execSync } from 'child_process';

function getTagMessage(tagName: string): string {
  try {
    // Get the tag message (annotation)
    const message = execSync(`git tag -l --format='%(contents)' ${tagName}`, {
      encoding: 'utf-8',
    }).trim();

    if (!message) {
      console.error(`No message found for tag ${tagName}`);
      process.exit(1);
    }

    return message;
  } catch (error) {
    console.error(`Failed to get tag message: ${error}`);
    process.exit(1);
  }
}

function main() {
  const tagName = process.argv[2];

  if (!tagName) {
    console.error('Usage: get-tag-message.ts <tag-name>');
    process.exit(1);
  }

  const message = getTagMessage(tagName);
  console.log(message);
}

main();
