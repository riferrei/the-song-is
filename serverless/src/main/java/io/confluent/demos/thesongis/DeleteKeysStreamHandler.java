package io.confluent.demos.thesongis;

import com.amazon.ask.Skill;
import com.amazon.ask.Skills;
import com.amazon.ask.SkillStreamHandler;

public class DeleteKeysStreamHandler extends SkillStreamHandler {

	private static Skill getSkill() {

		return Skills.standard()
			.addRequestHandlers(
				new CancelandStopIntentHandler(),
				new DeleteKeysIntentHandler(),
				new HelpIntentHandler(),
				new LaunchRequestHandler(),
				new SessionEndedRequestHandler())
			.build();

	}

	public DeleteKeysStreamHandler() {
		super(getSkill());
	}

}