package io.confluent.demos.thesongis;

import com.amazon.ask.Skill;
import com.amazon.ask.Skills;
import com.amazon.ask.SkillStreamHandler;

public class TheSongIsStreamHandler extends SkillStreamHandler {

	private static Skill getSkill() {

		return Skills.standard()
			.addRequestHandlers(
				new CancelandStopIntentHandler(),
				new TheSongIsIntentHandler(),
				new HelpIntentHandler(),
				new LaunchRequestHandler(),
				new SessionEndedRequestHandler())
			.build();

	}

	public TheSongIsStreamHandler() {
		super(getSkill());
	}

}