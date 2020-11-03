import { renderComponent, expect } from '../test_helper';
import CommentList from '../../src/components/comment_list';

describe('CommentList', () => {
	let component;
	beforeEach(() => {
		const props = {comments : ['New Comment', 'Good Comment' ] };
		component = renderComponent(CommentList, null, props);
	});

	it('should have an li', () => {
		expect(component.find('li').length).to.equal(2);
	});

	it('Should show each comment that is provided',  () => {
		expect(component).to.contain('New Comment');
		expect(component).to.contain('Good Comment');
	});
	
})

