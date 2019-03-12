package io.confluent.demos.currentidentity;

import com.amazon.ask.Skill;
import com.amazon.ask.Skills;
import com.amazon.ask.SkillStreamHandler;

public class CurrentIdentityStreamHandler extends SkillStreamHandler {

	private static Skill getSkill() {

		return Skills.standard()
			.addRequestHandlers(
				new CancelandStopIntentHandler(),
				new CurrentIdentityIntentHandler(),
				new HelpIntentHandler(),
				new LaunchRequestHandler(),
				new SessionEndedRequestHandler())
			.build();

	}

	public CurrentIdentityStreamHandler() {

		super(getSkill());

	}

}