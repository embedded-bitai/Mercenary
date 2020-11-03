import { renderComponent , expect } from '../test_helper';
import CommentBox from '../../src/components/comment_box';

describe('CommentBox', () => {
	let component;
	beforeEach(() => {
		component = renderComponent(CommentBox);
	});

	it('shuold have class', () => {
		expect(component).to.have.class('comment-box');
	})

	it('Should Have a Text Area',  () => {
		expect(component.find('textarea')).to.exist;
	});

	it('Should Have a Submit Button',  () => {
		expect(component.find('button')).to.exist;
	});

	describe('entered text', () => {

		beforeEach(() => {
			component.find('textarea').simulate('change', 'new comment');
		});	

		it('shows that a text is there in textarea',() => {
			expect(component.find('textarea')).to.have.value('new comment');
		});

		it('when submitted, clears the input',() => {
			console.log(component);
			component.simulate('submit');
			expect(component.find('textarea')).to.have.value('');	
		})
	})
})

